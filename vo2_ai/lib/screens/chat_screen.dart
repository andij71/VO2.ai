// lib/screens/chat_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../data/database.dart' hide ChatMessage;
import '../providers/chat_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/settings_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(chatProvider.notifier).loadMessages();
      SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final msg = text ?? _controller.text.trim();
    if (msg.isEmpty) return;
    _controller.clear();
    final pinned = ref.read(chatPinnedDayProvider);
    ref.read(chatProvider.notifier).sendMessage(msg, pinnedDay: pinned);
    // Clear pinned day after sending
    ref.read(chatPinnedDayProvider.notifier).state = null;
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _showDayPicker(AccentPreset accent) {
    final plan = ref.read(planProvider);
    if (plan.days == null || plan.days!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DayPickerSheet(
        days: plan.days!,
        accent: accent,
        onSelect: (day) {
          ref.read(chatPinnedDayProvider.notifier).state = day;
          Navigator.pop(context);
        },
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final accent = ref.watch(accentProvider);

    // Scroll to bottom whenever messages change
    SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return SafeArea(
      child: Column(
        children: [
          // Coach header
          _CoachHeader(accent: accent),
          // Messages
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(accent)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length + (messages.length < 3 ? 1 : 0),
                    itemBuilder: (context, i) {
                      // Show quick replies after last message if few messages
                      if (i == messages.length && messages.length < 3) {
                        return _QuickReplies(
                          accent: accent,
                          onTap: (text) => _send(text),
                        );
                      }
                      return _buildMessage(messages[i], accent, i);
                    },
                  ),
          ),
          _PinnedDayBanner(accent: accent),
          _buildInput(accent),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AccentPreset accent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.primary, const Color(0xFF8B9EFF)],
            ),
          ),
          child: const Icon(Icons.auto_awesome_rounded, size: 28, color: Color(0xFF0A0A0C)),
        ),
        const SizedBox(height: 16),
        const Text('Coach Aria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 6),
        const Text('Ask me anything about your training', style: TextStyle(fontSize: 14, color: PaceColors.textSecondary)),
        const SizedBox(height: 24),
        _QuickReplies(
          accent: accent,
          onTap: (text) => _send(text),
        ),
      ],
    );
  }

  Widget _buildMessage(ChatMessage msg, AccentPreset accent, int index) {
    final isUser = msg.role == 'user';

    if (msg.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _CoachAvatar(size: 28, accent: accent),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: _TypingDots(accent: accent),
            ),
          ],
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 30).clamp(0, 200)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              _CoachAvatar(size: 28, accent: accent),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? accent.dim : const Color.fromRGBO(255, 255, 255, 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 18),
                  ),
                  border: isUser
                      ? Border.all(color: accent.primary.withValues(alpha: 0.25), width: 0.5)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isUser ? Colors.white : const Color.fromRGBO(255, 255, 255, 0.85),
                        height: 1.45,
                      ),
                    ),
                    if (msg.hasPlanChange && msg.planActions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _PlanChangeCard(actions: msg.planActions, accent: accent),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(AccentPreset accent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.03),
            border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showDayPicker(accent),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(255, 255, 255, 0.06),
                    border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.1)),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: PaceColors.textSecondary, size: 17),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.1)),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Ask your coach...',
                      hintStyle: TextStyle(color: PaceColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.primary,
                    boxShadow: [BoxShadow(color: accent.glow, blurRadius: 12)],
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF0A0A0C), size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Coach header with avatar, status, and clear button
class _CoachHeader extends ConsumerWidget {
  final AccentPreset accent;
  const _CoachHeader({required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMessages = ref.watch(chatProvider).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          _CoachAvatar(size: 38, accent: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coach Aria', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PaceColors.easy,
                        boxShadow: [BoxShadow(color: PaceColors.easy.withValues(alpha: 0.5), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('Online', style: TextStyle(fontSize: 12, color: PaceColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          if (hasMessages)
            GestureDetector(
              onTap: () => ref.read(chatProvider.notifier).clearChat(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: PaceColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

// Coach avatar with gradient
class _CoachAvatar extends StatelessWidget {
  final double size;
  final AccentPreset accent;
  const _CoachAvatar({required this.size, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.primary, const Color(0xFF8B9EFF)],
        ),
      ),
      child: Icon(Icons.auto_awesome_rounded, size: size * 0.45, color: const Color(0xFF0A0A0C)),
    );
  }
}

// Animated typing dots
class _TypingDots extends StatefulWidget {
  final AccentPreset accent;
  const _TypingDots({required this.accent});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PaceColors.textSecondary.withValues(alpha: 0.3 + (_controllers[i].value * 0.7)),
              ),
            );
          },
        );
      }),
    );
  }
}

// Plan change visualization card
class _PlanChangeCard extends StatelessWidget {
  final List<PlanActionSummary> actions;
  final AccentPreset accent;
  const _PlanChangeCard({required this.actions, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.primary.withValues(alpha: 0.08),
        border: Border.all(color: accent.primary.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.edit_calendar_rounded, size: 14, color: accent.primary),
              const SizedBox(width: 6),
              Text(
                'Plan Updated',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...actions.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                Text(a.icon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    a.description,
                    style: const TextStyle(fontSize: 12, color: Color.fromRGBO(255, 255, 255, 0.7)),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// Quick reply suggestion chips
class _QuickReplies extends StatelessWidget {
  final AccentPreset accent;
  final ValueChanged<String> onTap;

  const _QuickReplies({required this.accent, required this.onTap});

  static const _suggestions = [
    'How do I improve my pace?',
    'Make Tuesday a rest day',
    'Swap my long run to Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _suggestions.map((text) {
          return GestureDetector(
            onTap: () => onTap(text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PaceRadii.pill),
                color: accent.dim,
                border: Border.all(color: accent.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: accent.primary, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Pinned day context banner above input
class _PinnedDayBanner extends ConsumerWidget {
  final AccentPreset accent;
  const _PinnedDayBanner({required this.accent});

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(chatPinnedDayProvider);
    if (pinned == null) return const SizedBox.shrink();

    final dayName = pinned.dayOfWeek >= 0 && pinned.dayOfWeek < 7
        ? _dayNames[pinned.dayOfWeek]
        : 'Day ${pinned.dayOfWeek}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08))),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: accent.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'W${pinned.week} $dayName — ${pinned.label}',
              style: TextStyle(fontSize: 13, color: accent.primary, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(chatPinnedDayProvider.notifier).state = null,
            child: const Icon(Icons.close_rounded, size: 16, color: PaceColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet day picker
class _DayPickerSheet extends StatelessWidget {
  final List<PlanDay> days;
  final AccentPreset accent;
  final ValueChanged<PlanDay> onSelect;

  const _DayPickerSheet({required this.days, required this.accent, required this.onSelect});

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    // Group by week
    final weeks = <int, List<PlanDay>>{};
    for (final d in days) {
      weeks.putIfAbsent(d.week, () => []).add(d);
    }
    final sortedWeeks = weeks.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, controller) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: PaceColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: accent.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Pin a training day',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: accent.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedWeeks.length,
                itemBuilder: (context, wi) {
                  final week = sortedWeeks[wi];
                  final weekDays = weeks[week]!..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 12, bottom: 6),
                        child: Text(
                          'Week $week',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: PaceColors.textSecondary),
                        ),
                      ),
                      ...weekDays.map((day) {
                        final dayName = day.dayOfWeek >= 0 && day.dayOfWeek < 7
                            ? _dayNames[day.dayOfWeek]
                            : '${day.dayOfWeek}';
                        final isRest = day.sessionType == 'rest';
                        return GestureDetector(
                          onTap: () => onSelect(day),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    dayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isRest ? PaceColors.textMuted : Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    day.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isRest ? PaceColors.textMuted : const Color.fromRGBO(255, 255, 255, 0.8),
                                    ),
                                  ),
                                ),
                                if (!isRest) ...[
                                  Text(
                                    '${day.distanceKm}km',
                                    style: const TextStyle(fontSize: 12, color: PaceColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
