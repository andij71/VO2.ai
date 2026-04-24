// lib/services/account_delete_service.dart
//
// Coordinates a full account-and-data wipe. This is what Apple's App Store
// Review guideline 5.1.1(v) requires for any app that has an "account"
// concept — and Strava counts even though we have no backend.
//
// Steps, in safe order (best-effort; we continue on individual failures so
// a temporarily offline Strava API doesn't block the local wipe):
//
//   1. Deauthorize Strava (network call to Strava).
//   2. Clear Strava tokens from Keychain (flutter_secure_storage).
//   3. Clear OpenRouter API key from Keychain.
//   4. Wipe the Drift SQLite tables (plans, sessions, chat, profiles,
//      settings — including disclaimer acceptance and model prefs).
//   5. Clear SharedPreferences (athlete name cache).
//
// This service exposes progress via a callback so the UI can show a
// lightweight step indicator. It never throws; failures are collected and
// returned so the UI can show a summary.

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../services/strava_service.dart';

typedef DeleteProgress = void Function(String step);

class AccountDeleteResult {
  final bool success;
  final List<String> failures;

  const AccountDeleteResult({required this.success, this.failures = const []});
}

class AccountDeleteService {
  final AppDatabase _db;
  final StravaService _strava;
  final FlutterSecureStorage _secureStorage;

  AccountDeleteService({
    required AppDatabase db,
    required StravaService strava,
    FlutterSecureStorage? secureStorage,
  })  : _db = db,
        _strava = strava,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<AccountDeleteResult> deleteEverything({
    DeleteProgress? onProgress,
  }) async {
    final failures = <String>[];

    void step(String label) {
      debugPrint('[AccountDelete] $label');
      onProgress?.call(label);
    }

    // 1) Strava deauthorize (network). Best-effort.
    step('Disconnecting Strava');
    try {
      await _strava.disconnect();
    } catch (e) {
      failures.add('Strava deauthorize failed: $e');
    }

    // 2) Secure storage — wipe everything we own.
    step('Clearing secure storage');
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      failures.add('Secure storage wipe failed: $e');
    }

    // 3) Drift DB — wipe every table. Order matters for FK-referenced rows.
    step('Erasing local database');
    try {
      await _db.transaction(() async {
        await _db.delete(_db.chatMessages).go();
        await _db.delete(_db.planDays).go();
        await _db.delete(_db.trainingPlans).go();
        await _db.delete(_db.userProfiles).go();
        await _db.delete(_db.settings).go();
      });
    } catch (e) {
      failures.add('Database wipe failed: $e');
    }

    // 4) SharedPreferences — athlete name cache etc.
    step('Clearing preferences');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      failures.add('Preferences wipe failed: $e');
    }

    step('Done');
    return AccountDeleteResult(
      success: failures.isEmpty,
      failures: failures,
    );
  }
}
