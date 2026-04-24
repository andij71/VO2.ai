// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../data/database.dart';
import '../providers/plan_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/strava_provider.dart';
import '../services/strava_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/accent_pill.dart';
import '../widgets/ring_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider);
    final strava = ref.watch(stravaProvider);
    final accent = ref.watch(accentProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Greeting
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: PaceColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strava.athleteName ?? 'Runner',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
                  ),
                ],
              ),
            ),
          ),

          // Next Session Card
          if (plan.state == PlanState.ready && plan.days != null && plan.days!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _NextSessionCard(
                  day: _findNextSession(plan.days!, plan.startDate),
                  accent: accent,
                ),
              ),
            ),

          // Status message if no plan
          if (plan.state != PlanState.ready)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.directions_run_rounded, size: 40, color: accent.dim),
                        const SizedBox(height: 12),
                        const Text(
                          'No training plan yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Go to the Plan tab to generate your personalized plan',
                          style: TextStyle(fontSize: 13, color: PaceColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Strava stats or connect prompt
          if (strava.state == StravaState.ready && strava.activities.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _StravaStatsGrid(activities: strava.activities, accent: accent),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _TrainingStatsGrid(plan: plan, accent: accent),
              ),
            ),

          // Recent Strava Runs
          if (strava.state == StravaState.ready && strava.activities.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _RecentRunsCard(
                  activities: strava.activities,
                  accent: accent,
                  onRefresh: () => ref.read(stravaProvider.notifier).fetchActivities(),
                ),
              ),
            ),

          // Weekly Volume
          if (plan.state == PlanState.ready && plan.days != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _WeeklyVolumeCard(days: plan.days!, accent: accent),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  PlanDay? _findNextSession(List<PlanDay> days, DateTime? startDate) {
    if (startDate == null) {
      // Fallback: first non-rest, non-completed day
      for (final day in days) {
        if (day.sessionType != 'rest' && !day.completed) return day;
      }
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find the first non-rest, non-completed day on or after today
    for (final day in days) {
      if (day.sessionType == 'rest' || day.completed) continue;
      final dayDate = startDate.add(Duration(days: (day.week - 1) * 7 + day.dayOfWeek));
      final dayDateOnly = DateTime(dayDate.year, dayDate.month, dayDate.day);
      if (!dayDateOnly.isBefore(today)) return day;
    }
    return null;
  }
}

class _NextSessionCard extends StatelessWidget {
  final PlanDay? day;
  final AccentPreset accent;

  const _NextSessionCard({required this.day, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox.shrink();

    final typeColor = switch (day!.sessionType) {
      'easy' => PaceColors.easy,
      'tempo' => PaceColors.tempo,
      'long' => PaceColors.long,
      'rest' => PaceColors.rest,
      'interval' => PaceColors.interval,
      _ => Colors.white,
    };

    return GlassCard(
      glow: true,
      glowColor: accent.glow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'NEXT SESSION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: accent.primary,
                  ),
                ),
                const Spacer(),
                AccentPill(label: day!.sessionType.toUpperCase(), color: typeColor),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              day!.label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(icon: Icons.straighten_rounded, label: '${day!.distanceKm} km'),
                const SizedBox(width: 16),
                _StatChip(icon: Icons.speed_rounded, label: '${day!.targetPace}/km'),
                const SizedBox(width: 16),
                _StatChip(icon: Icons.local_fire_department_rounded, label: 'Zone ${day!.effortZone}'),
              ],
            ),
            if (day!.notes != null && day!.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                day!.notes!,
                style: const TextStyle(fontSize: 13, color: PaceColors.textSecondary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: PaceColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PaceColors.textSecondary)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final double progress;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                RingChart(
                  progress: progress.clamp(0.0, 1.0),
                  color: color,
                  size: 32,
                  strokeWidth: 3,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(width: 3),
                Text(unit, style: const TextStyle(fontSize: 13, color: PaceColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StravaStatsGrid extends StatelessWidget {
  final List<StravaActivity> activities;
  final AccentPreset accent;

  const _StravaStatsGrid({required this.activities, required this.accent});

  @override
  Widget build(BuildContext context) {
    final totalKm = activities.fold<double>(0, (s, a) => s + a.distanceKm);
    final totalRuns = activities.length;
    final avgPaces = activities.where((a) => a.averageSpeed > 0).toList();
    final avgSpeed = avgPaces.isEmpty
        ? 0.0
        : avgPaces.fold<double>(0, (s, a) => s + a.averageSpeed) / avgPaces.length;
    final avgPaceSecs = avgSpeed > 0 ? 1000 / avgSpeed : 0.0;
    final avgMins = avgPaceSecs ~/ 60;
    final avgSecs = (avgPaceSecs % 60).round();
    final longestRun = activities.fold<double>(0, (m, a) => a.distanceKm > m ? a.distanceKm : m);

    final weeksSpan = activities.isNotEmpty
        ? (DateTime.now().difference(activities.last.startDate).inDays / 7).ceil().clamp(1, 52)
        : 1;
    final weeklyKm = totalKm / weeksSpan;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatTile(
              label: 'WEEKLY AVG',
              value: weeklyKm.toStringAsFixed(1),
              unit: 'km/wk',
              color: accent.primary,
              progress: (weeklyKm / 50).clamp(0.0, 1.0),
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(
              label: 'AVG PACE',
              value: '$avgMins:${avgSecs.toString().padLeft(2, '0')}',
              unit: '/km',
              color: const Color(0xFF8B9EFF),
              progress: avgPaceSecs > 0 ? (1 - (avgPaceSecs - 240) / 240).clamp(0.0, 1.0) : 0,
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatTile(
              label: 'TOTAL RUNS',
              value: '$totalRuns',
              unit: 'runs',
              color: PaceColors.easy,
              progress: (totalRuns / 30).clamp(0.0, 1.0),
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(
              label: 'LONGEST RUN',
              value: longestRun.toStringAsFixed(1),
              unit: 'km',
              color: PaceColors.tempo,
              progress: (longestRun / 42).clamp(0.0, 1.0),
            )),
          ],
        ),
      ],
    );
  }
}

class _TrainingStatsGrid extends StatelessWidget {
  final PlanStatus plan;
  final AccentPreset accent;

  const _TrainingStatsGrid({required this.plan, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (plan.state != PlanState.ready || plan.days == null) {
      return const SizedBox.shrink();
    }
    final days = plan.days!;
    final totalSessions = days.where((d) => d.sessionType != 'rest').length;
    final completed = days.where((d) => d.completed).length;
    final totalKm = days.fold<double>(0, (s, d) => s + d.distanceKm);
    final weeks = days.isEmpty ? 0 : days.map((d) => d.week).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatTile(
              label: 'TOTAL SESSIONS',
              value: '$totalSessions',
              unit: 'runs',
              color: accent.primary,
              progress: weeks > 0 ? completed / totalSessions : 0,
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(
              label: 'PLAN VOLUME',
              value: totalKm.toStringAsFixed(0),
              unit: 'km',
              color: const Color(0xFF8B9EFF),
              progress: (totalKm / 200).clamp(0.0, 1.0),
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatTile(
              label: 'WEEKS',
              value: '$weeks',
              unit: 'total',
              color: PaceColors.easy,
              progress: weeks > 0 ? 1.0 : 0,
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(
              label: 'COMPLETED',
              value: '$completed',
              unit: 'of $totalSessions',
              color: PaceColors.tempo,
              progress: totalSessions > 0 ? completed / totalSessions : 0,
            )),
          ],
        ),
      ],
    );
  }
}

class _WeeklyVolumeCard extends StatelessWidget {
  final List<PlanDay> days;
  final AccentPreset accent;

  const _WeeklyVolumeCard({required this.days, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Get week 1 data for display
    final week1 = days.where((d) => d.week == 1).toList();
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxDist = week1.fold<double>(0, (m, d) => d.distanceKm > m ? d.distanceKm : m);
    final totalDist = week1.fold<double>(0, (s, d) => s + d.distanceKm);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'WEEKLY VOLUME',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: PaceColors.textTertiary),
                ),
                const Spacer(),
                Text(
                  '${totalDist.toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final dayData = week1.where((d) => d.dayOfWeek == i).toList();
                  final dist = dayData.isNotEmpty ? dayData.first.distanceKm : 0.0;
                  final fraction = maxDist > 0 ? dist / maxDist : 0.0;
                  final typeColor = dayData.isNotEmpty
                      ? switch (dayData.first.sessionType) {
                          'easy' => PaceColors.easy,
                          'tempo' => PaceColors.tempo,
                          'long' => PaceColors.long,
                          'rest' => PaceColors.rest,
                          'interval' => PaceColors.interval,
                          _ => accent.primary,
                        }
                      : PaceColors.rest;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: fraction > 0 ? fraction.clamp(0.08, 1.0) : 0.08,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: dist > 0 ? typeColor.withValues(alpha: 0.6) : PaceColors.textMuted.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dayNames[i],
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: PaceColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Recent runs card with refresh and tap-to-detail
class _RecentRunsCard extends StatelessWidget {
  final List<StravaActivity> activities;
  final AccentPreset accent;
  final VoidCallback onRefresh;

  const _RecentRunsCard({
    required this.activities,
    required this.accent,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/strava_logo.png', height: 10),
                const SizedBox(width: 6),
                const Text(
                  'RECENT RUNS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: PaceColors.textTertiary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(255, 255, 255, 0.06),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 16, color: PaceColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...activities.take(5).map((run) => GestureDetector(
              onTap: () => _showRunDetail(context, run),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${run.startDate.day}.${run.startDate.month}.',
                        style: const TextStyle(fontSize: 12, color: PaceColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        run.name,
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${run.distanceKm.toStringAsFixed(1)}km',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PaceColors.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      run.pacePerKm,
                      style: const TextStyle(fontSize: 13, color: PaceColors.textMuted),
                    ),
                  ],
                ),
              ),
            )),
            if (activities.length > 5)
              GestureDetector(
                onTap: () => _showAllRuns(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Show all ${activities.length} runs',
                    style: TextStyle(fontSize: 13, color: accent.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRunDetail(BuildContext context, StravaActivity run) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RunDetailSheet(run: run),
    );
  }

  void _showAllRuns(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _AllRunsSheet(activities: activities),
    );
  }
}

// Single run detail bottom sheet
class _RunDetailSheet extends StatelessWidget {
  final StravaActivity run;
  const _RunDetailSheet({required this.run});

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: run.movingTimeSeconds);
    final hrs = duration.inHours;
    final mins = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;
    final durationStr = hrs > 0
        ? '${hrs}h ${mins}m'
        : '${mins}m ${secs}s';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: PaceColors.textMuted, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            run.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${run.startDate.day}.${run.startDate.month}.${run.startDate.year}',
            style: const TextStyle(fontSize: 14, color: PaceColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _DetailStat(label: 'Distance', value: '${run.distanceKm.toStringAsFixed(2)} km'),
              _DetailStat(label: 'Duration', value: durationStr),
              _DetailStat(label: 'Pace', value: '${run.pacePerKm}/km'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DetailStat(label: 'Elevation', value: '${run.totalElevationGain.toStringAsFixed(0)} m'),
              if (run.hasHeartrate && run.averageHeartrate != null)
                _DetailStat(label: 'Avg HR', value: '${run.averageHeartrate!.round()} bpm'),
              _DetailStat(label: 'Type', value: run.type),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: PaceColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

// All runs list bottom sheet
class _AllRunsSheet extends StatelessWidget {
  final List<StravaActivity> activities;
  const _AllRunsSheet({required this.activities});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: PaceColors.textMuted, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Image.asset('assets/strava_logo.png', height: 10),
                  const SizedBox(width: 8),
                  Text(
                    '${activities.length} Runs (last 90 days)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: activities.length,
                itemBuilder: (context, i) {
                  final run = activities[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF121214),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => _RunDetailSheet(run: run),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${run.startDate.day}.${run.startDate.month}.',
                              style: const TextStyle(fontSize: 13, color: PaceColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(run.name, style: const TextStyle(fontSize: 14, color: Colors.white), overflow: TextOverflow.ellipsis),
                                Text(
                                  '${run.distanceKm.toStringAsFixed(1)}km  ·  ${run.pacePerKm}/km  ·  ${run.durationFormatted}',
                                  style: const TextStyle(fontSize: 12, color: PaceColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
