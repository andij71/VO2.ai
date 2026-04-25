// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/pace_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next == AuthState.authenticated) {
        context.go('/setup');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                'Connect AI',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste your OpenRouter API key to power the AI coach.',
                style: TextStyle(fontSize: 14, color: PaceColors.textSecondary),
              ),
              const SizedBox(height: 32),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'sk-or-...',
                      hintStyle: TextStyle(color: PaceColors.textMuted),
                      border: InputBorder.none,
                    ),
                    obscureText: true,
                  ),
                ),
              ),
              if (authState == AuthState.invalid) ...[
                const SizedBox(height: 12),
                const Text(
                  'Invalid API key. Please check and try again.',
                  style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              PaceButton(
                label: authState == AuthState.validating
                    ? 'Validating...'
                    : 'Connect',
                enabled: authState != AuthState.validating,
                onPressed: () {
                  final key = _controller.text.trim();
                  if (key.isNotEmpty) {
                    ref.read(authProvider.notifier).setKey(key);
                  }
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    launchUrl(Uri.parse('https://openrouter.ai/keys'),
                        mode: LaunchMode.inAppBrowserView);
                  },
                  child: const Text(
                    'Get an API key from OpenRouter',
                    style: TextStyle(
                        color: PaceColors.textSecondary, fontSize: 13),
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
