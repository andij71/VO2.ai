// lib/screens/disclaimer_screen.dart
//
// Medical / safety disclaimer gate. Shown once per install (or when the
// disclaimer version bumps). Persists acceptance in the Settings table via
// the disclaimerProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/disclaimer_text.dart';
import '../providers/disclaimer_provider.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/pace_button.dart';

class DisclaimerScreen extends ConsumerStatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  ConsumerState<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends ConsumerState<DisclaimerScreen> {
  bool _accepted = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final accent = AccentPreset.volt;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: AmbientBackground(
        accent: accent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.dim,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: accent.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        DisclaimerText.title(lang),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: Text(
                            DisclaimerText.body(lang),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: PaceColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _saving
                      ? null
                      : () => setState(() => _accepted = !_accepted),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: PaceDurations.fast,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _accepted
                                ? accent.primary
                                : PaceColors.textMuted,
                            width: 1.5,
                          ),
                          color: _accepted
                              ? accent.primary
                              : Colors.transparent,
                        ),
                        child: _accepted
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Color(0xFF0A0A0C),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DisclaimerText.acceptLabel(lang),
                          style: const TextStyle(
                            fontSize: 14,
                            color: PaceColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PaceButton(
                  label: _saving
                      ? '...'
                      : DisclaimerText.continueLabel(lang),
                  enabled: _accepted && !_saving,
                  onPressed: _accepted && !_saving ? _onContinue : null,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    setState(() => _saving = true);
    await ref.read(disclaimerProvider.notifier).accept();
    if (!mounted) return;
    context.go('/welcome');
  }
}
