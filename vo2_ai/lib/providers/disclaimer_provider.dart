// lib/providers/disclaimer_provider.dart
//
// Tracks whether the user has accepted the medical/safety disclaimer.
// Uses the existing Settings table (drift) with a versioned key so that a
// future update to the disclaimer text can force re-acceptance by bumping
// the version suffix.

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import 'database_provider.dart';

/// Bump this when the disclaimer text changes in a legally meaningful way.
/// Old acceptance records remain in the DB (audit trail), but the user will
/// be prompted to accept the new version.
const disclaimerVersion = 'v1';
const _disclaimerKey = 'disclaimer_accepted_$disclaimerVersion';

enum DisclaimerStatus { unknown, accepted, notAccepted }

class DisclaimerNotifier extends StateNotifier<DisclaimerStatus> {
  final AppDatabase _db;

  DisclaimerNotifier(this._db) : super(DisclaimerStatus.unknown) {
    // Kick off the initial read immediately — the router treats `unknown` as
    // "still loading" so no premature redirects happen.
    load();
  }

  /// Reads the current acceptance state from the Settings table.
  Future<void> load() async {
    final rows = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(_disclaimerKey)))
        .get();
    state = rows.isNotEmpty
        ? DisclaimerStatus.accepted
        : DisclaimerStatus.notAccepted;
  }

  /// Called from the disclaimer screen when the user taps Continue with the
  /// checkbox ticked.
  Future<void> accept() async {
    final timestamp = DateTime.now().toIso8601String();
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: _disclaimerKey, value: timestamp),
        );
    state = DisclaimerStatus.accepted;
  }

  /// Wipes the acceptance record. Called from the delete-account flow.
  Future<void> reset() async {
    await (_db.delete(_db.settings)
          ..where((t) => t.key.like('disclaimer_accepted_%')))
        .go();
    state = DisclaimerStatus.notAccepted;
  }
}

final disclaimerProvider =
    StateNotifierProvider<DisclaimerNotifier, DisclaimerStatus>((ref) {
  final db = ref.watch(databaseProvider);
  return DisclaimerNotifier(db);
});
