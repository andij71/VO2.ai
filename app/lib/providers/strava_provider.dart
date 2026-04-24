// lib/providers/strava_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/strava_service.dart';
import 'plan_provider.dart';

enum StravaState { disconnected, connecting, connected, loading, ready, error }

class StravaStatus {
  final StravaState state;
  final List<StravaActivity> activities;
  final String? athleteName;
  final String? errorMessage;

  const StravaStatus({
    this.state = StravaState.disconnected,
    this.activities = const [],
    this.athleteName,
    this.errorMessage,
  });

  /// AI-ready summary of recent runs
  String get aiSummary => StravaService.summarizeForAI(activities);
}

class StravaNotifier extends StateNotifier<StravaStatus> {
  final StravaService _service;
  final Ref _ref;

  StravaNotifier(this._service, this._ref) : super(const StravaStatus());

  StravaService get service => _service;

  /// Check if previously connected — auto-fetch activities if so
  Future<void> init() async {
    final loaded = await _service.loadTokens();
    if (loaded) {
      state = StravaStatus(
        state: StravaState.connected,
        athleteName: _service.athleteName,
      );
      // Re-fetch activities on app start
      await fetchActivities();
    }
  }

  /// Trigger OAuth flow (in-app browser, no deep link needed)
  Future<void> authenticate() async {
    state = const StravaStatus(state: StravaState.connecting);
    debugPrint('[StravaProvider] Starting authentication...');

    final success = await _service.authenticate();
    if (success) {
      state = StravaStatus(
        state: StravaState.connected,
        athleteName: _service.athleteName,
      );
      // Auto-fetch activities after connecting
      await fetchActivities();
    } else {
      state = const StravaStatus(
        state: StravaState.error,
        errorMessage: 'Failed to connect to Strava',
      );
    }
  }

  /// Fetch recent running activities
  Future<void> fetchActivities() async {
    state = StravaStatus(
      state: StravaState.loading,
      athleteName: state.athleteName,
    );

    final runs = await _service.fetchRecentRuns();
    state = StravaStatus(
      state: StravaState.ready,
      activities: runs,
      athleteName: state.athleteName,
    );

    debugPrint('[StravaProvider] Loaded ${runs.length} activities');

    // Auto-sync: mark matching plan days as completed
    if (runs.isNotEmpty) {
      try {
        final matched = await _ref.read(planProvider.notifier).syncWithStrava(runs);
        if (matched > 0) {
          debugPrint('[StravaProvider] Auto-completed $matched plan days');
        }
      } catch (e) {
        debugPrint('[StravaProvider] Sync failed: $e');
      }
    }
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    state = const StravaStatus();
  }
}

final stravaProvider = StateNotifierProvider<StravaNotifier, StravaStatus>((ref) {
  return StravaNotifier(StravaService(), ref);
});
