// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/strava_provider.dart';
import '../widgets/glass_card.dart';
import 'delete_account_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(settingsProvider);
    final strava = ref.watch(stravaProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back_ios_rounded,
                      color: PaceColors.textSecondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Settings',
                    style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
            const SizedBox(height: 32),

            // Profile section
            const Text('PROFILE',
                style: TextStyle(
                    fontSize: 11,
                    color: PaceColors.textTertiary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Goal', _goalLabel(setup.goal)),
                    const Divider(
                        color: Color.fromRGBO(255, 255, 255, 0.08), height: 24),
                    _row('Level', setup.level ?? '—'),
                    const Divider(
                        color: Color.fromRGBO(255, 255, 255, 0.08), height: 24),
                    _row('Days/week', '${setup.daysPerWeek}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Strava section
            const Text('STRAVA',
                style: TextStyle(
                    fontSize: 11,
                    color: PaceColors.textTertiary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              glow: strava.state == StravaState.connected ||
                  strava.state == StravaState.ready,
              glowColor: const Color(0xFFFC4C02).withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color:
                                const Color(0xFFFC4C02).withValues(alpha: 0.15),
                          ),
                          alignment: Alignment.center,
                          child:
                              Image.asset('assets/strava_logo.png', height: 12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Strava',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              _stravaStatusText(strava),
                            ],
                          ),
                        ),
                        _stravaAction(strava, ref),
                      ],
                    ),
                    if (strava.state == StravaState.ready &&
                        strava.activities.isNotEmpty) ...[
                      const Divider(
                          color: Color.fromRGBO(255, 255, 255, 0.08),
                          height: 20),
                      Row(
                        children: [
                          Text(
                            '${strava.activities.length} runs',
                            style: const TextStyle(
                                fontSize: 13, color: PaceColors.textSecondary),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => ref
                                .read(stravaProvider.notifier)
                                .fetchActivities(),
                            child: const Text('Refresh',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFFC4C02),
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Accent color
            const Text('APPEARANCE',
                style: TextStyle(
                    fontSize: 11,
                    color: PaceColors.textTertiary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Accent Color',
                            style:
                                TextStyle(color: Colors.white, fontSize: 15))),
                    _colorDot(
                        AccentPreset.volt.primary,
                        setup.accentColor == 'volt',
                        () => ref
                            .read(settingsProvider.notifier)
                            .setAccentColor('volt')),
                    const SizedBox(width: 12),
                    _colorDot(
                        AccentPreset.violet.primary,
                        setup.accentColor == 'violet',
                        () => ref
                            .read(settingsProvider.notifier)
                            .setAccentColor('violet')),
                    const SizedBox(width: 12),
                    _colorDot(
                        AccentPreset.cyan.primary,
                        setup.accentColor == 'cyan',
                        () => ref
                            .read(settingsProvider.notifier)
                            .setAccentColor('cyan')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // AI Model
            const Text('AI MODEL',
                style: TextStyle(
                    fontSize: 11,
                    color: PaceColors.textTertiary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: availableModels.map((m) {
                    final (id, name, price) = m;
                    final selected = setup.aiModel == id;
                    return GestureDetector(
                      onTap: () =>
                          ref.read(settingsProvider.notifier).setAiModel(id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? AccentPreset.volt.primary
                                      : const Color.fromRGBO(
                                          255, 255, 255, 0.2),
                                  width: 1.5,
                                ),
                                color: selected
                                    ? AccentPreset.volt.primary
                                    : Colors.transparent,
                              ),
                              child: selected
                                  ? const Icon(Icons.check,
                                      size: 12, color: Color(0xFF0A0A0C))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: selected
                                        ? Colors.white
                                        : PaceColors.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  )),
                            ),
                            Text(price,
                                style: const TextStyle(
                                    fontSize: 12, color: PaceColors.textMuted)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // API section
            const Text('AI CONNECTION',
                style: TextStyle(
                    fontSize: 11,
                    color: PaceColors.textTertiary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Provider', 'OpenRouter'),
                    const Divider(
                        color: Color.fromRGBO(255, 255, 255, 0.08), height: 24),
                    GestureDetector(
                      onTap: () {
                        ref.read(authProvider.notifier).clearKey();
                        context.go('/auth');
                      },
                      child: const Row(
                        children: [
                          Text('Disconnect',
                              style: TextStyle(
                                  color: Color(0xFFFF6B6B), fontSize: 15)),
                          Spacer(),
                          Icon(Icons.logout_rounded,
                              color: Color(0xFFFF6B6B), size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Privacy & Legal
            const Text('PRIVACY & LEGAL',
                style: TextStyle(
                    fontSize: 11,
                    color: PaceColors.textTertiary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse(
                            'https://andij71.github.io/VO2.ai/privacy/'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Row(
                        children: [
                          Text('Privacy Policy',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15)),
                          Spacer(),
                          Icon(Icons.arrow_outward_rounded,
                              color: PaceColors.textTertiary, size: 18),
                        ],
                      ),
                    ),
                    const Divider(
                        color: Color.fromRGBO(255, 255, 255, 0.08), height: 24),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse('https://github.com/andij71/VO2.ai'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Row(
                        children: [
                          Text('Open Source on GitHub',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15)),
                          Spacer(),
                          Icon(Icons.arrow_outward_rounded,
                              color: PaceColors.textTertiary, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Danger zone — Apple guideline 5.1.1(v) compliance
            const Text('DANGER ZONE',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF6B6B),
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => showDeleteAccountSheet(context),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delete Account & Data',
                                style: TextStyle(
                                    color: Color(0xFFFF6B6B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text(
                                'Permanently removes all local data and disconnects Strava',
                                style: TextStyle(
                                    color: PaceColors.textTertiary,
                                    fontSize: 12,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFFF6B6B), size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // App Version & Logo
            Center(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AccentPreset.volt.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/app_logo.png'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'VO2.ai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: PaceColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _stravaStatusText(StravaStatus strava) {
    return switch (strava.state) {
      StravaState.disconnected => const Text('Connect to personalize your plan',
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

  Widget _stravaAction(StravaStatus strava, WidgetRef ref) {
    if (strava.state == StravaState.connecting ||
        strava.state == StravaState.loading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child:
            CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFC4C02)),
      );
    }

    if (strava.state == StravaState.connected ||
        strava.state == StravaState.ready) {
      return GestureDetector(
        onTap: () => ref.read(stravaProvider.notifier).disconnect(),
        child: const Text('Disconnect',
            style: TextStyle(fontSize: 13, color: Color(0xFFFF6B6B))),
      );
    }

    return GestureDetector(
      onTap: () async {
        await ref.read(stravaProvider.notifier).authenticate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PaceRadii.pill),
          color: const Color(0xFFFC4C02),
        ),
        child: const Text('Connect',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        const Spacer(),
        Text(value,
            style:
                const TextStyle(color: PaceColors.textSecondary, fontSize: 15)),
      ],
    );
  }

  Widget _colorDot(Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: selected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
              : null,
        ),
      ),
    );
  }

  String _goalLabel(String? goal) {
    return switch (goal) {
      'sub20' => 'Sub-20 5K',
      'hm' => 'Half Marathon',
      'fm' => 'Full Marathon',
      'speed' => 'Speed Builder',
      _ => '—',
    };
  }
}
