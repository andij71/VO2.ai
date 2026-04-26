// lib/screens/disclaimer_screen.dart
//
// Medical / safety disclaimer gate. Shown once per install (or when the
// disclaimer version bumps). Persists acceptance in the Settings table via
// the disclaimerProvider.
//
// Dark glassmorphic style — matches the rest of the app.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
    final lang = Localizations.localeOf(context).languageCode;
    const accent = AccentPreset.volt;

    const eyebrowStyle = TextStyle(
      fontFamily: '.SF Pro Display',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
      color: PaceColors.textTertiary,
    );
    const titleStyle = TextStyle(
      fontFamily: '.SF Pro Display',
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.6,
      color: PaceColors.textPrimary,
    );
    const bodyStyle = TextStyle(
      fontFamily: '.SF Pro Display',
      fontSize: 14,
      height: 1.6,
      color: PaceColors.textSecondary,
    );
    const acceptStyle = TextStyle(
      fontFamily: '.SF Pro Display',
      fontSize: 14,
      color: PaceColors.textPrimary,
      height: 1.4,
    );

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

                // Header — small icon + eyebrow
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.dim,
                        border: Border.all(
                          color: accent.glow,
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.favorite_border_rounded,
                        color: accent.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('BEFORE YOU START', style: eyebrowStyle),
                  ],
                ),
                const SizedBox(height: 16),

                Text(DisclaimerText.title(lang), style: titleStyle),

                const SizedBox(height: 20),

                // Body card — glassmorphic, scrollable
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: ScrollbarTheme(
                      data: ScrollbarThemeData(
                        thumbColor: WidgetStateProperty.all(
                          PaceColors.textMuted,
                        ),
                      ),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: MarkdownBody(
                            data: DisclaimerText.body(lang),
                            styleSheet: MarkdownStyleSheet(
                              p: bodyStyle,
                              h1: bodyStyle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: PaceColors.textPrimary,
                              ),
                              h2: bodyStyle.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: PaceColors.textPrimary,
                              ),
                              h3: bodyStyle.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: PaceColors.textPrimary,
                              ),
                              listBullet: bodyStyle,
                              strong: bodyStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: PaceColors.textPrimary,
                              ),
                              em: bodyStyle.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              blockSpacing: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Accept checkbox
                GestureDetector(
                  onTap: _saving
                      ? null
                      : () => setState(() => _accepted = !_accepted),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: PaceDurations.fast,
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _accepted
                                ? accent.primary
                                : PaceColors.cardBorder,
                            width: 1.5,
                          ),
                          color: _accepted
                              ? accent.primary
                              : Colors.transparent,
                        ),
                        child: _accepted
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: PaceColors.background,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DisclaimerText.acceptLabel(lang),
                          style: acceptStyle,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Continue CTA
                PaceButton(
                  label: _saving ? '...' : DisclaimerText.continueLabel(lang),
                  onPressed: _accepted && !_saving ? _onContinue : null,
                  enabled: _accepted && !_saving,
                ),

                const SizedBox(height: 24),
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
