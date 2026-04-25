// lib/router.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/goal_setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/disclaimer_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/ambient_background.dart';

/// Notifier that triggers GoRouter refresh when auth or setup state changes
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(settingsProvider.select((s) => s.isComplete), (_, __) => notifyListeners());
    ref.listen(disclaimerProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Read current values at redirect time — don't watch them
      final authState = ref.read(authProvider);
      final isSetupComplete = ref.read(settingsProvider).isComplete;
      final disclaimerStatus = ref.read(disclaimerProvider);

      // Wait for async initial reads to complete before deciding anything.
      if (authState == AuthState.unknown) return null;
      if (disclaimerStatus == DisclaimerStatus.unknown) return null;

      final path = state.uri.path;
      final isDisclaimerPath = path == '/disclaimer';
      final isAuthPath = path == '/welcome' || path == '/auth';
      final isSetupPath = path == '/setup';

      // Medical disclaimer gate runs before everything else.
      if (disclaimerStatus == DisclaimerStatus.notAccepted) {
        return isDisclaimerPath ? null : '/disclaimer';
      }
      // Once accepted, don't let the user sit on the disclaimer screen.
      if (disclaimerStatus == DisclaimerStatus.accepted && isDisclaimerPath) {
        return '/welcome';
      }

      if (authState == AuthState.authenticated) {
        if (isAuthPath) {
          return isSetupComplete ? '/home' : '/setup';
        }
        if (!isSetupComplete && !isSetupPath) {
          return '/setup';
        }
        return null;
      }

      if (authState == AuthState.unauthenticated || authState == AuthState.invalid) {
        return isAuthPath ? null : '/welcome';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/disclaimer',
        builder: (context, state) => const DisclaimerScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const GoalSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/plan',
              builder: (context, state) => const PlanScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const ChatScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentProvider);

    return Scaffold(
      body: AmbientBackground(
        accent: accent,
        child: navigationShell,
      ),
      bottomNavigationBar: _GlassTabBar(
        currentIndex: navigationShell.currentIndex,
        accent: accent,
        onTap: (i) => navigationShell.goBranch(i,
            initialLocation: i == navigationShell.currentIndex),
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final AccentPreset accent;
  final ValueChanged<int> onTap;

  const _GlassTabBar({
    required this.currentIndex,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.calendar_today_rounded, 'Plan'),
      (Icons.chat_bubble_outline_rounded, 'Coach'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 6,
          ),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.04),
            border: const Border(
              top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              final (icon, label) = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(PaceRadii.pill),
                            color: isActive ? accent.dim : Colors.transparent,
                          ),
                          child: Icon(
                            icon,
                            size: 22,
                            color: isActive ? accent.primary : PaceColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? accent.primary : PaceColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
