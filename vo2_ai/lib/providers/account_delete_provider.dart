// lib/providers/account_delete_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/account_delete_service.dart';
import 'database_provider.dart';
import 'strava_provider.dart';

final accountDeleteServiceProvider = Provider<AccountDeleteService>((ref) {
  final db = ref.watch(databaseProvider);
  final strava = ref.watch(stravaProvider.notifier).service;
  return AccountDeleteService(db: db, strava: strava);
});
