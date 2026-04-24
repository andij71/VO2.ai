// lib/screens/plan_screen.dart

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../data/database.dart';
import '../providers/chat_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/settings_provider.dart' show settingsProvider, accentProvider;
import '../services/calendar_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/accent_pill.dart';
import '../widgets/loading_orbit.dart';
import '../widgets/pace_button.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  @override
  void initState() {
    super.initState();
    final plan = ref.read(planProvider);
    if (plan.state == PlanState.idle) {
      Future.microtask(() => ref.read(planProvider.notifier).generatePlan());
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProvider);
    final accent = ref.watch(accentProvider);

    return SafeArea(
      child: switch (plan.state) {
        PlanState.idle || PlanState.generating => _LoadingView(accent: accent),
        PlanState.ready => _PlanView(days: plan.days!, accent: accent, startDate: plan.startDate),
        PlanState.error => _buildError(plan.errorMessage ?? 'Unknown error'),
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: PaceColors.textMuted),
            const SizedBox(height: 16),
            const Text('Something went wrong', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 13, color: PaceColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => ref.read(planProvider.notifier).generatePlan(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated loading state with rotating messages
class _LoadingView extends StatefulWidget {
  final AccentPreset accent;
  const _LoadingView({required this.accent});

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView> {
  int _msgIndex = 0;
  static const _messages = [
    'Analyzing your goals...',
    'Calculating optimal load...',
    'Building your plan...',
    'Personalizing intensities...',
  ];

  @override
  void initState() {
    super.initState();
    _cycleMessages();
  }

  void _cycleMessages() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingOrbit(color: widget.accent.primary),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _messages[_msgIndex],
              key: ValueKey(_msgIndex),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Plan view with stat cards and animated day rows
class _PlanView extends ConsumerWidget {
  final List<PlanDay> days;
  final AccentPreset accent;
  final DateTime? startDate;

  const _PlanView({required this.days, required this.accent, this.startDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeks = <int, List<PlanDay>>{};
    for (final day in days) {
      weeks.putIfAbsent(day.week, () => []).add(day);
    }

    final totalRuns = days.where((d) => d.sessionType != 'rest').length;
    final peakWeekKm = weeks.entries.map((e) =>
      e.value.fold<double>(0, (s, d) => s + d.distanceKm)
    ).fold<double>(0, (a, b) => a > b ? a : b);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('YOUR PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: accent.primary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(PaceRadii.pill),
                          color: const Color.fromRGBO(255, 107, 107, 0.1),
                          border: Border.all(color: const Color.fromRGBO(255, 107, 107, 0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFFF6B6B)),
                            SizedBox(width: 4),
                            Text('Delete', style: TextStyle(fontSize: 12, color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Training Schedule', style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
          ),
        ),

        // Stat cards row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: _StatCard(label: 'Total Runs', value: '$totalRuns', accent: accent)),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: 'Peak Week', value: '${peakWeekKm.toStringAsFixed(0)} km', accent: accent)),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: 'Weeks', value: '${weeks.length}', accent: accent)),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Weekly timeline
        ...weeks.entries.map((entry) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4, top: 8),
                  child: Text(
                    _weekHeader(entry.key),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PaceColors.textTertiary, letterSpacing: 0.8),
                  ),
                ),
                ...entry.value.asMap().entries.map((dayEntry) {
                  final d = dayEntry.value;
                  final isToday = startDate != null && _isDayToday(d, startDate!);
                  return _DayRow(
                    day: d,
                    accent: accent,
                    animDelay: dayEntry.key * 60,
                    isToday: isToday,
                  );
                }),
              ],
            ),
          ),
        )),

        // Export to calendar button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            child: PaceButton(
              label: 'Export to Calendar',
              onPressed: () => _showCalendarExport(context),
            ),
          ),
        ),
      ],
    );
  }

  static const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _weekHeader(int weekNum) {
    if (startDate == null) return 'WEEK $weekNum';
    final weekStart = startDate!.add(Duration(days: (weekNum - 1) * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return 'WEEK $weekNum — ${_monthNames[weekStart.month - 1]} ${weekStart.day} – ${_monthNames[weekEnd.month - 1]} ${weekEnd.day}';
  }

  bool _isDayToday(PlanDay day, DateTime start) {
    final dayDate = start.add(Duration(days: (day.week - 1) * 7 + day.dayOfWeek));
    final now = DateTime.now();
    return dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Plan?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete your current training plan. You can generate a new one afterwards.',
          style: TextStyle(color: PaceColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: PaceColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(planProvider.notifier).deletePlan();
              await ref.read(chatProvider.notifier).clearChat();
              await ref.read(settingsProvider.notifier).resetSetup();
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  void _showCalendarExport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalendarExportSheet(days: days, accent: accent),
    );
  }
}

class _CalendarExportSheet extends StatefulWidget {
  final List<PlanDay> days;
  final AccentPreset accent;

  const _CalendarExportSheet({required this.days, required this.accent});

  @override
  State<_CalendarExportSheet> createState() => _CalendarExportSheetState();
}

class _CalendarExportSheetState extends State<_CalendarExportSheet> {
  final _calService = CalendarService();
  List<Calendar>? _calendars;
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    final granted = await _calService.requestPermission();
    if (!granted) {
      setState(() {
        _loading = false;
        _error = 'Calendar permission denied';
      });
      return;
    }
    final cals = await _calService.getCalendars();
    setState(() {
      _calendars = cals;
      _loading = false;
    });
  }

  Future<void> _export(String calendarId) async {
    setState(() => _exporting = true);
    final result = await _calService.exportPlan(
      calendarId: calendarId,
      days: widget.days,
      planStartDate: DateTime.now().add(const Duration(days: 1)), // Start tomorrow
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: result.success ? const Color(0xFF1A1A1C) : const Color(0xFF3A1010),
        content: Text(
          result.success
              ? '${result.eventsAdded} sessions added to calendar'
              : 'Export failed: ${result.error}',
          style: const TextStyle(color: Colors.white),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111113),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.1))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: PaceColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Export to Calendar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: widget.accent.primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick a calendar to add your training sessions',
            style: TextStyle(fontSize: 13, color: PaceColors.textSecondary),
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14)),
            ),

          if (_calendars != null && !_exporting)
            ...(_calendars!.isEmpty
                ? [const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No writable calendars found', style: TextStyle(color: PaceColors.textSecondary)),
                  )]
                : _calendars!.map((cal) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _export(cal.id!),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: PaceColors.cardBg,
                          border: Border.all(color: PaceColors.cardBorder, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(cal.color ?? 0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cal.name ?? 'Calendar',
                                style: const TextStyle(fontSize: 15, color: Colors.white),
                              ),
                            ),
                            if (cal.accountName != null)
                              Text(
                                cal.accountName!,
                                style: const TextStyle(fontSize: 12, color: PaceColors.textMuted),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: PaceColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  )).toList()),

          if (_exporting)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 12),
                  Text('Adding sessions...', style: TextStyle(color: PaceColors.textSecondary, fontSize: 13)),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final AccentPreset accent;

  const _StatCard({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent.primary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: PaceColors.textTertiary, letterSpacing: 0.4)),
          ],
        ),
      ),
    );
  }
}

// Animated day row with timeline dot
class _DayRow extends StatefulWidget {
  final PlanDay day;
  final AccentPreset accent;
  final int animDelay;
  final bool isToday;

  const _DayRow({required this.day, required this.accent, required this.animDelay, this.isToday = false});

  @override
  State<_DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<_DayRow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _slideAnim = Tween(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.animDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final isToday = widget.isToday;
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final typeColor = switch (day.sessionType) {
      'easy' => PaceColors.easy,
      'tempo' => PaceColors.tempo,
      'long' => PaceColors.long,
      'rest' => PaceColors.rest,
      'interval' => PaceColors.interval,
      _ => Colors.white,
    };

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              // Timeline dot
              Column(
                children: [
                  Container(
                    width: isToday ? 12 : 10,
                    height: isToday ? 12 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: typeColor,
                      boxShadow: [
                        BoxShadow(color: typeColor.withValues(alpha: isToday ? 0.7 : 0.4), blurRadius: isToday ? 10 : 6),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isToday ? typeColor.withValues(alpha: 0.08) : PaceColors.cardBg,
                    border: Border.all(
                      color: isToday ? typeColor.withValues(alpha: 0.4) : PaceColors.cardBorder,
                      width: isToday ? 1.2 : 0.5,
                    ),
                    boxShadow: isToday
                        ? [BoxShadow(color: typeColor.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 0)]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        dayNames[day.dayOfWeek],
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: typeColor),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: typeColor.withValues(alpha: 0.2),
                          ),
                          child: Text('TODAY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: typeColor, letterSpacing: 0.5)),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(day.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                            if (day.sessionType != 'rest')
                              Text(
                                '${day.distanceKm} km · ${day.targetPace}/km',
                                style: const TextStyle(fontSize: 12, color: PaceColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      AccentPill(label: day.sessionType.toUpperCase(), color: typeColor),
                      const SizedBox(width: 8),
                      // Completion indicator
                      day.completed
                          ? Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: PaceColors.easy.withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.check_rounded, size: 14, color: PaceColors.easy),
                            )
                          : const Icon(Icons.chevron_right_rounded, size: 18, color: PaceColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
