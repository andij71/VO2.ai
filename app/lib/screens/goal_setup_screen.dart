// lib/screens/goal_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/settings_provider.dart';
import '../providers/strava_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/pace_button.dart';

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  int _step = 0; // 0=goal, 1=level, 2=training details, 3=strava

  static const _goals = [
    {
      'id': 'sub20',
      'label': 'Sub-20 5K',
      'icon': '\u26A1',
      'desc': 'Break 4:00/km pace',
      'time': '8 weeks'
    },
    {
      'id': 'hm',
      'label': 'Half Marathon',
      'icon': '\uD83C\uDFC3',
      'desc': 'Complete 21.1 km',
      'time': '12 weeks'
    },
    {
      'id': 'fm',
      'label': 'Full Marathon',
      'icon': '\uD83C\uDFC6',
      'desc': '42.2 km PR',
      'time': '16 weeks'
    },
    {
      'id': 'speed',
      'label': 'Speed Builder',
      'icon': '\uD83D\uDD25',
      'desc': '1K time trial PR',
      'time': '6 weeks'
    },
  ];

  static const _levels = [
    {
      'id': 'beginner',
      'label': 'Beginner',
      'desc': '< 20 km/week \u00B7 first structured plan'
    },
    {
      'id': 'intermediate',
      'label': 'Intermediate',
      'desc': '20\u201350 km/week \u00B7 1+ race completed'
    },
    {
      'id': 'advanced',
      'label': 'Advanced',
      'desc': '50+ km/week \u00B7 performance focus'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(settingsProvider);
    final accent = ref.watch(accentProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'AI COACH',
                style: TextStyle(
                    fontSize: 13,
                    color: PaceColors.textSecondary,
                    letterSpacing: 0.3),
              ),
              const SizedBox(height: 4),
              Text('Build Your Plan',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 20),
              // Step indicator (4 steps)
              Row(
                children: List.generate(
                    4,
                    (i) => Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              color: i <= _step
                                  ? accent.primary
                                  : const Color.fromRGBO(255, 255, 255, 0.12),
                              boxShadow: i <= _step
                                  ? [
                                      BoxShadow(
                                          color: accent.glow, blurRadius: 8)
                                    ]
                                  : null,
                            ),
                          ),
                        )),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: switch (_step) {
                  0 => _buildGoalStep(setup, accent),
                  1 => _buildLevelStep(setup, accent),
                  2 => _buildTrainingDetailsStep(setup, accent),
                  _ => _buildStravaStep(accent),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalStep(UserSetup setup, AccentPreset accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What\'s your goal?',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            children: _goals.map((g) {
              final selected = setup.goal == g['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setGoal(g['id']!),
                  child: GlassCard(
                    glow: selected,
                    glowColor: accent.glow,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: selected
                                  ? accent.dim
                                  : const Color.fromRGBO(255, 255, 255, 0.06),
                            ),
                            alignment: Alignment.center,
                            child: Text(g['icon']!,
                                style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g['label']!,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? accent.primary
                                            : Colors.white)),
                                const SizedBox(height: 2),
                                Text('${g['desc']} \u00B7 ${g['time']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: PaceColors.textSecondary)),
                              ],
                            ),
                          ),
                          _radioCircle(selected, accent),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        PaceButton(
          label: 'Continue \u2192',
          enabled: setup.goal != null,
          onPressed: () => setState(() => _step = 1),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLevelStep(UserSetup setup, AccentPreset accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your experience level',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 6),
        const Text('This helps calibrate weekly mileage and intensity.',
            style: TextStyle(fontSize: 13, color: PaceColors.textSecondary)),
        const SizedBox(height: 18),
        ..._levels.map((l) {
          final selected = setup.level == l['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () =>
                  ref.read(settingsProvider.notifier).setLevel(l['id']!),
              child: GlassCard(
                glow: selected,
                glowColor: accent.glow,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l['label']!,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? accent.primary
                                        : Colors.white)),
                            const SizedBox(height: 3),
                            Text(l['desc']!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: PaceColors.textSecondary)),
                          ],
                        ),
                      ),
                      _radioCircle(selected, accent),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _step = 0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PaceRadii.button),
                    color: const Color.fromRGBO(255, 255, 255, 0.07),
                    border: Border.all(
                        color: const Color.fromRGBO(255, 255, 255, 0.12)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('\u2190 Back',
                      style: TextStyle(
                          color: PaceColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PaceButton(
                label: 'Continue \u2192',
                enabled: setup.level != null,
                onPressed: () => setState(() => _step = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTrainingDetailsStep(UserSetup setup, AccentPreset accent) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Training details',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 6),
        const Text(
          'Fine-tune your plan with your schedule and current fitness.',
          style: TextStyle(fontSize: 13, color: PaceColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Running days selector
        const Text('RUNNING DAYS',
            style: TextStyle(
                fontSize: 11,
                color: PaceColors.textTertiary,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final selected = setup.runningDays.contains(i);
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  final days = List<int>.from(setup.runningDays);
                  if (selected) {
                    if (days.length > 1) days.remove(i);
                  } else {
                    days.add(i);
                    days.sort();
                  }
                  ref.read(settingsProvider.notifier).setRunningDays(days);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? accent.primary.withValues(alpha: 0.12)
                        : PaceColors.cardBg,
                    border: Border.all(
                      color: selected
                          ? accent.primary.withValues(alpha: 0.5)
                          : PaceColors.cardBorder,
                      width: 0.5,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: accent.glow, blurRadius: 16, spreadRadius: -4)]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayNames[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? accent.primary : PaceColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 2),
          child: Text(
            '${setup.runningDays.length} days/week',
            style:
                const TextStyle(fontSize: 12, color: PaceColors.textSecondary),
          ),
        ),
        const SizedBox(height: 24),

        // Weekly km slider
        const Text('CURRENT WEEKLY VOLUME',
            style: TextStyle(
                fontSize: 11,
                color: PaceColors.textTertiary,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: accent.primary,
                  inactiveTrackColor: const Color.fromRGBO(255, 255, 255, 0.08),
                  thumbColor: accent.primary,
                  overlayColor: accent.primary.withValues(alpha: 0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: (setup.weeklyKm ?? 20).clamp(0, 120),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setWeeklyKm(v),
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                '${(setup.weeklyKm ?? 20).toStringAsFixed(0)} km',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accent.primary),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Mobility toggle
        GestureDetector(
          onTap: () =>
              ref.read(settingsProvider.notifier).setMobility(!setup.mobility),
          child: GlassCard(
            glow: setup.mobility,
            glowColor: accent.glow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: setup.mobility
                          ? accent.dim
                          : const Color.fromRGBO(255, 255, 255, 0.06),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.self_improvement_rounded,
                        size: 22,
                        color: setup.mobility
                            ? accent.primary
                            : PaceColors.textMuted),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mobility / Strength',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        SizedBox(height: 2),
                        Text('I do additional mobility or strength work',
                            style: TextStyle(
                                fontSize: 12, color: PaceColors.textSecondary)),
                      ],
                    ),
                  ),
                  _radioCircle(setup.mobility, accent),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Pro session names toggle
        GestureDetector(
          onTap: () => ref.read(settingsProvider.notifier).setProNames(!setup.proNames),
          child: GlassCard(
            glow: setup.proNames,
            glowColor: accent.glow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: setup.proNames ? accent.dim : const Color.fromRGBO(255, 255, 255, 0.06),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.bolt_rounded, size: 22, color: setup.proNames ? accent.primary : PaceColors.textMuted),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pro Session Names', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Viby names like "Threshold Surge" instead of "Tempo Run"', style: TextStyle(fontSize: 12, color: PaceColors.textSecondary)),
                      ],
                    ),
                  ),
                  _radioCircle(setup.proNames, accent),
                ],
              ),
            ),
          ),
        ),

        const Spacer(),

        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _step = 1),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PaceRadii.button),
                    color: const Color.fromRGBO(255, 255, 255, 0.07),
                    border: Border.all(
                        color: const Color.fromRGBO(255, 255, 255, 0.12)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('\u2190 Back',
                      style: TextStyle(
                          color: PaceColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PaceButton(
                label: 'Continue \u2192',
                onPressed: () => setState(() => _step = 3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStravaStep(AccentPreset accent) {
    final strava = ref.watch(stravaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Connect your training data',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 6),
        const Text(
          'Share your recent runs so the AI can build a plan based on your actual fitness.',
          style: TextStyle(fontSize: 13, color: PaceColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Strava connect card
        GlassCard(
          glow: strava.state == StravaState.connected ||
              strava.state == StravaState.ready,
          glowColor:
              const Color(0xFFFC4C02).withValues(alpha: 0.2), // Strava orange
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Strava logo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFFC4C02).withValues(alpha: 0.15),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset('assets/strava_logo.png', height: 14),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Strava',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          _stravaStatusText(strava),
                        ],
                      ),
                    ),
                    _stravaActionWidget(strava, accent),
                  ],
                ),

                // Show activity summary when loaded
                if (strava.state == StravaState.ready &&
                    strava.activities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color.fromRGBO(255, 255, 255, 0.04),
                      border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strava.activities.length} runs found',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accent.primary),
                        ),
                        const SizedBox(height: 8),
                        // Show last 3 runs
                        ...strava.activities.take(3).map((run) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Text(
                                    '${run.startDate.day}/${run.startDate.month}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: PaceColors.textMuted,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      run.name,
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${run.distanceKm.toStringAsFixed(1)}km',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: PaceColors.textSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    run.pacePerKm,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: PaceColors.textTertiary),
                                  ),
                                ],
                              ),
                            )),
                        if (strava.activities.length > 3)
                          Text(
                            '+${strava.activities.length - 3} more',
                            style: const TextStyle(
                                fontSize: 11, color: PaceColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (strava.state == StravaState.error)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              strava.errorMessage ?? 'Connection failed',
              style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B)),
            ),
          ),

        const Spacer(),

        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _step = 2),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PaceRadii.button),
                    color: const Color.fromRGBO(255, 255, 255, 0.07),
                    border: Border.all(
                        color: const Color.fromRGBO(255, 255, 255, 0.12)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('\u2190 Back',
                      style: TextStyle(
                          color: PaceColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PaceButton(
                label: strava.state == StravaState.ready
                    ? 'Generate Plan'
                    : 'Skip for now',
                onPressed: () => context.go('/plan'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _stravaStatusText(StravaStatus strava) {
    return switch (strava.state) {
      StravaState.disconnected => const Text('Tap to connect',
          style: TextStyle(fontSize: 12, color: PaceColors.textSecondary)),
      StravaState.connecting => const Text('Connecting...',
          style: TextStyle(fontSize: 12, color: Color(0xFFFC4C02))),
      StravaState.connected => Text(
          'Connected as ${strava.athleteName ?? 'athlete'}',
          style: const TextStyle(fontSize: 12, color: PaceColors.easy)),
      StravaState.loading => const Text('Loading activities...',
          style: TextStyle(fontSize: 12, color: Color(0xFFFC4C02))),
      StravaState.ready => Text('${strava.activities.length} runs imported',
          style: const TextStyle(fontSize: 12, color: PaceColors.easy)),
      StravaState.error => const Text('Connection failed',
          style: TextStyle(fontSize: 12, color: Color(0xFFFF6B6B))),
    };
  }

  Widget _stravaActionWidget(StravaStatus strava, AccentPreset accent) {
    if (strava.state == StravaState.connecting ||
        strava.state == StravaState.loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child:
            CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFC4C02)),
      );
    }

    if (strava.state == StravaState.connected ||
        strava.state == StravaState.ready) {
      return const Icon(Icons.check_circle_rounded,
          color: PaceColors.easy, size: 24);
    }

    return GestureDetector(
      onTap: _connectStrava,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PaceRadii.pill),
          color: const Color(0xFFFC4C02),
        ),
        child: const Text(
          'Connect',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _connectStrava() async {
    await ref.read(stravaProvider.notifier).authenticate();
  }

  Widget _radioCircle(bool selected, AccentPreset accent) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? accent.primary
              : const Color.fromRGBO(255, 255, 255, 0.2),
          width: 1.5,
        ),
        color: selected ? accent.primary : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: Color(0xFF0A0A0C))
          : null,
    );
  }
}
