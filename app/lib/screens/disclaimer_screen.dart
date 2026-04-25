// lib/screens/disclaimer_screen.dart
//
// Medical / safety disclaimer gate. Shown once per install (or when the
// disclaimer version bumps). Persists acceptance in the Settings table via
// the disclaimerProvider.
//
// Visual style matches the public landing page + WelcomeScreen — this and
// /welcome together form the "editorial pre-screens" before the user enters
// the dark functional UI at /auth.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../core/disclaimer_text.dart';
import '../providers/disclaimer_provider.dart';

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

    final eyebrowStyle = GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
      color: BrandPalette.muted,
    );
    final titleStyle = GoogleFonts.instrumentSerif(
      fontSize: 28,
      fontStyle: FontStyle.italic,
      height: 1.2,
      color: BrandPalette.ink,
      letterSpacing: -0.3,
    );
    final bodyStyle = GoogleFonts.inter(
      fontSize: 14,
      height: 1.6,
      color: BrandPalette.ink,
    );
    final acceptStyle = GoogleFonts.inter(
      fontSize: 14,
      color: BrandPalette.ink,
      height: 1.4,
    );
    final ctaStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: BrandPalette.paper,
    );

    return Scaffold(
      backgroundColor: BrandPalette.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Header — small icon + eyebrow + serif title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrandPalette.accent.withValues(alpha: 0.12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: BrandPalette.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'BEFORE YOU START',
                    style: eyebrowStyle,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                DisclaimerText.title(lang),
                style: titleStyle,
              ),

              const SizedBox(height: 20),

              // Body card — sunken paper with hairline
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: BrandPalette.paperSunk,
                    borderRadius: BorderRadius.circular(PaceRadii.card),
                    border: Border.all(
                      color: BrandPalette.paperBorder,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: ScrollbarTheme(
                      data: ScrollbarThemeData(
                        thumbColor: WidgetStateProperty.all(
                          BrandPalette.subtle.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: Text(
                            DisclaimerText.body(lang),
                            style: bodyStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Accept checkbox — ink-on-paper, no glow
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
                              ? BrandPalette.ink
                              : BrandPalette.subtle,
                          width: 1.5,
                        ),
                        color: _accepted
                            ? BrandPalette.ink
                            : Colors.transparent,
                      ),
                      child: _accepted
                          ? Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: BrandPalette.paper,
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

              // Continue CTA — same dark fill as Welcome's "Get started"
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _accepted && !_saving ? _onContinue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandPalette.ink,
                    foregroundColor: BrandPalette.paper,
                    disabledBackgroundColor:
                        BrandPalette.ink.withValues(alpha: 0.25),
                    disabledForegroundColor:
                        BrandPalette.paper.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _saving ? '...' : DisclaimerText.continueLabel(lang),
                    style: ctaStyle,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
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
