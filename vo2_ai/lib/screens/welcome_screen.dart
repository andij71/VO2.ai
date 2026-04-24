// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../widgets/pace_button.dart';
import '../widgets/ambient_background.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AccentPreset.volt;

    return Scaffold(
      body: AmbientBackground(
        accent: accent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // App icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: accent.glow, blurRadius: 40)],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'VO2.ai',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: accent.primary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your AI running coach',
                  style: TextStyle(fontSize: 17, color: PaceColors.textSecondary),
                ),
                const Spacer(flex: 3),
                PaceButton(
                  label: 'Get Started',
                  onPressed: () => context.go('/auth'),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
