// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eyebrowStyle = GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
      color: BrandPalette.muted,
    );
    final taglineStyle = GoogleFonts.instrumentSerif(
      fontSize: 24,
      fontStyle: FontStyle.italic,
      height: 1.35,
      color: BrandPalette.ink,
      letterSpacing: -0.2,
    );
    final finePrintStyle = GoogleFonts.inter(
      fontSize: 12,
      color: BrandPalette.muted,
      height: 1.5,
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
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Eyebrow
              Text(
                'OPEN-SOURCE iOS APP  ·  BRING YOUR OWN KEY',
                style: eyebrowStyle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Wordmark — uses the brand-style logo asset (italic serif + dot)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Image.asset(
                  'assets/app_logo_full.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 28),

              // Editorial tagline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text.rich(
                  TextSpan(
                    style: taglineStyle,
                    children: const [
                      TextSpan(text: 'Your AI running coach.\n'),
                      TextSpan(text: 'Without giving up '),
                      TextSpan(
                        text: 'your data',
                        style: TextStyle(color: BrandPalette.accent),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 3),

              // CTA — dark fill, cream text
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => context.go('/auth'),
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandPalette.ink,
                    foregroundColor: BrandPalette.paper,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Get started', style: ctaStyle),
                ),
              ),

              const SizedBox(height: 16),

              // Fineprint
              Text(
                'Not a medical device. For training guidance only.',
                style: finePrintStyle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
