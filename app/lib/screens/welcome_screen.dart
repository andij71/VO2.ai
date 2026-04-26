// lib/screens/welcome_screen.dart
//
// First impression after launch. Dark glassmorphic style — same visual
// language as the rest of the app and the public landing page.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../widgets/ambient_background.dart';
import '../widgets/pace_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AmbientBackground(
        accent: AccentPreset.volt,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: _WelcomeBody(),
          ),
        ),
      ),
    );
  }
}

class _WelcomeBody extends StatelessWidget {
  const _WelcomeBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(flex: 2),

        // Eyebrow
        Text(
          'OPEN-SOURCE iOS APP  ·  BRING YOUR OWN KEY',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: PaceColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 36),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Image.asset(
            'assets/app_logo_transparent.png',
            fit: BoxFit.contain,
          ),
        ),

        // Big "V." wordmark — white V, volt dot. Same brand cue as the
        // landing nav-logo and the splash screen.
        // const _BigWordmark(),

        const SizedBox(height: 36),

        // Tagline
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.5,
              color: PaceColors.textPrimary,
            ),
            children: const [
              TextSpan(text: 'Your AI running coach.\n'),
              TextSpan(
                text: 'Without giving up ',
                style: TextStyle(color: PaceColors.textSecondary),
              ),
              TextSpan(
                text: 'your data',
                style: TextStyle(color: Color(0xFFC8FF00)),
              ),
              TextSpan(
                text: '.',
                style: TextStyle(color: PaceColors.textSecondary),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        const Spacer(flex: 3),

        // CTA
        PaceButton(
          label: 'Get started',
          onPressed: () => context.go('/auth'),
        ),

        const SizedBox(height: 16),

        // Fineprint
        const Text(
          'Not a medical device. For training guidance only.',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 12,
            color: PaceColors.textTertiary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

/// Big "VO2." wordmark in the brand style — white "VO2" with a volt dot.
/// Rendered as text (not an image) so it scales crisply on every device
/// and respects the system font stack.
class _BigWordmark extends StatelessWidget {
  const _BigWordmark();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 72,
          fontWeight: FontWeight.w800,
          letterSpacing: -3,
          color: PaceColors.textPrimary,
          height: 1,
        ),
        children: [
          TextSpan(text: 'VO2'),
          TextSpan(
            text: '.',
            style: TextStyle(color: Color(0xFFC8FF00)),
          ),
        ],
      ),
    );
  }
}
