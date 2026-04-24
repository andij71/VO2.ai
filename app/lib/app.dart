// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'router.dart';
import 'providers/auth_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/strava_provider.dart';

class PaceApp extends ConsumerStatefulWidget {
  const PaceApp({super.key});

  @override
  ConsumerState<PaceApp> createState() => _PaceAppState();
}

class _PaceAppState extends ConsumerState<PaceApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authProvider.notifier).init();
      ref.read(stravaProvider.notifier).init();
      ref.read(planProvider.notifier).loadExistingPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'VO2.ai',
      theme: PaceTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
