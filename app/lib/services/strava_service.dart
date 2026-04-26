// lib/services/strava_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strava_client/strava_client.dart';

/// Thin wrapper around strava_client for VO2.ai.
/// Auth is handled by the package via flutter_web_auth (in-app browser).
class StravaService {
  static const _clientId = String.fromEnvironment('STRAVA_CLIENT_ID');
  static const _clientSecret = String.fromEnvironment('STRAVA_CLIENT_SECRET');
  static const _redirectUrl = 'vo2ai://redirect';
  static const _callbackScheme = 'vo2ai';

  late final StravaClient _client;

  StravaService() {
    _client = StravaClient(
      secret: _clientSecret,
      clientId: _clientId,
    );
  }

  bool _isConnected = false;
  String? _athleteName;

  bool get isConnected => _isConnected;
  String? get athleteName => _athleteName;

  static const _keyAthleteName = 'strava_athlete_name';

  /// Check if we have a stored token from a previous session
  Future<bool> loadTokens() async {
    try {
      final token = await _client.getStravaAuthToken();
      if (token != null && token.accessToken.isNotEmpty) {
        _isConnected = true;
        // Load cached athlete name
        final prefs = await SharedPreferences.getInstance();
        _athleteName = prefs.getString(_keyAthleteName);
        debugPrint('[Strava] Loaded existing token, athlete: $_athleteName');
        return true;
      }
    } catch (e) {
      debugPrint('[Strava] No stored token: $e');
    }
    return false;
  }

  /// Trigger OAuth flow (opens in-app browser, handles redirect)
  Future<bool> authenticate() async {
    try {
      debugPrint('[Strava] Starting authentication...');
      await _client.authentication.authenticate(
        scopes: [
          AuthenticationScope.activity_read_all,
        ],
        redirectUrl: _redirectUrl,
        callbackUrlScheme: _callbackScheme,
      );
      _isConnected = true;
      // Fetch and persist athlete name
      try {
        final athlete = await _client.athletes.getAuthenticatedAthlete();
        _athleteName = athlete.firstname;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyAthleteName, _athleteName ?? '');
      } catch (_) {}
      debugPrint('[Strava] Authenticated: $_athleteName');
      return true;
    } catch (e) {
      final msg = e is Exception ? e.toString() : '$e';
      // Try to extract Fault message if available
      try {
        final dynamic fault = e;
        debugPrint('[Strava] Authentication failed: ${fault.message ?? msg}');
      } catch (_) {
        debugPrint('[Strava] Authentication failed: $msg');
      }
      return false;
    }
  }

  /// Ensure we have a valid (non-expired) token before making API calls
  Future<bool> _ensureValidToken() async {
    try {
      // authenticate() checks for existing token + refreshes if expired
      await _client.authentication.authenticate(
        scopes: [AuthenticationScope.activity_read_all],
        redirectUrl: _redirectUrl,
        callbackUrlScheme: _callbackScheme,
      );
      return true;
    } catch (e) {
      debugPrint('[Strava] Token refresh failed: $e');
      return false;
    }
  }

  /// Fetch recent run activities (last 90 days)
  Future<List<StravaActivity>> fetchRecentRuns({int count = 30}) async {
    if (!_isConnected) return [];

    // Refresh token if expired before fetching
    if (!await _ensureValidToken()) return [];

    try {
      debugPrint('[Strava] Fetching recent activities...');
      final now = DateTime.now();
      final after = now.subtract(const Duration(days: 90));

      final activities = await _client.activities.listLoggedInAthleteActivities(
        now,
        after,
        1,
        count,
      );

      final runs = activities
          .where((a) =>
              a.type == 'Run' || a.type == 'TrailRun' || a.type == 'VirtualRun')
          .map(_toStravaActivity)
          .toList();

      debugPrint('[Strava] Found ${runs.length} runs');
      return runs;
    } catch (e) {
      debugPrint('[Strava] Fetch activities failed: $e');
      return [];
    }
  }

  /// Fetch detailed activity by ID (includes splits, segments, laps)
  Future<DetailedStravaActivity?> fetchDetailedActivity(int activityId) async {
    if (!_isConnected) return null;
    if (!await _ensureValidToken()) return null;

    try {
      debugPrint('[Strava] Fetching detailed activity $activityId...');
      final detail = await _client.activities.getActivity(activityId);
      return DetailedStravaActivity(
        splits: detail.splitsMetric
                ?.map((s) => SplitData(
                      split: s.split ?? 0,
                      distanceMeters: s.distance ?? 0,
                      movingTimeSeconds: s.movingTime ?? 0,
                      averageSpeed: s.averageSpeed ?? 0,
                      elevationDiff: s.elevationDifference ?? 0,
                      paceZone: s.paceZone ?? 0,
                    ))
                .toList() ??
            [],
        segments: detail.segmentEfforts
                ?.map((e) => SegmentEffortData(
                      name: e.name ?? e.segment?.name ?? 'Segment',
                      distanceMeters: e.distance ?? e.segment?.distance ?? 0,
                      elapsedTimeSeconds: e.elapsedTime ?? 0,
                      movingTimeSeconds: e.movingTime ?? 0,
                      prRank: e.prRank,
                      komRank: e.komRank,
                      averageGrade: e.segment?.averageGrade,
                    ))
                .toList() ??
            [],
        calories: detail.calories ?? 0,
        maxSpeed: detail.maxSpeed ?? 0,
        averageCadence: detail.averageCadence,
        sufferScore: detail.sufferScore?.toDouble(),
        prCount: detail.prCount ?? 0,
        deviceName: detail.deviceName,
      );
    } catch (e) {
      debugPrint('[Strava] Fetch detailed activity failed: $e');
      return null;
    }
  }

  /// Disconnect / deauthorize
  Future<void> disconnect() async {
    try {
      await _client.authentication.deAuthorize();
    } catch (_) {}
    _isConnected = false;
    _athleteName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAthleteName);
    debugPrint('[Strava] Disconnected');
  }

  /// Convert strava_client SummaryActivity to our StravaActivity
  static StravaActivity _toStravaActivity(SummaryActivity a) {
    return StravaActivity(
      id: a.id ?? 0,
      name: a.name ?? 'Activity',
      type: a.type ?? 'Run',
      distanceMeters: a.distance ?? 0,
      movingTimeSeconds: a.movingTime ?? 0,
      averageSpeed: a.averageSpeed ?? 0,
      totalElevationGain: a.totalElevationGain ?? 0,
      startDate: a.startDateLocal != null
          ? DateTime.parse(a.startDateLocal!)
          : DateTime.now(),
      hasHeartrate: a.hasHeartrate ?? false,
      averageHeartrate: a.averageHeartrate,
    );
  }

  /// Summarize recent runs as context for AI plan generation
  static String summarizeForAI(List<StravaActivity> runs) {
    if (runs.isEmpty) return '';

    final totalKm = runs.fold<double>(0, (s, r) => s + r.distanceKm);
    final avgPaces = runs.where((r) => r.averageSpeed > 0).toList();
    final avgSpeed = avgPaces.isEmpty
        ? 0.0
        : avgPaces.fold<double>(0, (s, r) => s + r.averageSpeed) /
            avgPaces.length;
    final avgPaceSecsPerKm = avgSpeed > 0 ? 1000 / avgSpeed : 0.0;
    final avgPaceMins = avgPaceSecsPerKm ~/ 60;
    final avgPaceSecs = (avgPaceSecsPerKm % 60).round();

    final weeksSpan = runs.isNotEmpty
        ? (DateTime.now().difference(runs.last.startDate).inDays / 7).ceil()
        : 1;
    final weeklyKm = weeksSpan > 0 ? totalKm / weeksSpan : totalKm;

    final longestRun =
        runs.fold<double>(0, (m, r) => r.distanceKm > m ? r.distanceKm : m);

    final buf = StringBuffer();
    buf.writeln(
        'RECENT TRAINING DATA (from Strava, last ${runs.length} runs):');
    buf.writeln('- Period: last $weeksSpan weeks');
    buf.writeln('- Total runs: ${runs.length}');
    buf.writeln('- Weekly average: ${weeklyKm.toStringAsFixed(1)} km/week');
    buf.writeln(
        '- Average pace: $avgPaceMins:${avgPaceSecs.toString().padLeft(2, '0')}/km');
    buf.writeln('- Longest run: ${longestRun.toStringAsFixed(1)} km');
    buf.writeln('- Total volume: ${totalKm.toStringAsFixed(1)} km');

    buf.writeln('\nLast 5 runs:');
    for (final run in runs.take(5)) {
      buf.writeln(
          '  ${run.startDate.toIso8601String().substring(0, 10)}: ${run.distanceKm.toStringAsFixed(1)}km @ ${run.pacePerKm}/km (${run.durationFormatted})');
    }

    return buf.toString();
  }
}

/// Our own lightweight activity model (decoupled from strava_client)
class StravaActivity {
  final int id;
  final String name;
  final String type;
  final double distanceMeters;
  final int movingTimeSeconds;
  final double averageSpeed; // m/s
  final double totalElevationGain;
  final DateTime startDate;
  final bool hasHeartrate;
  final double? averageHeartrate;

  const StravaActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceMeters,
    required this.movingTimeSeconds,
    required this.averageSpeed,
    required this.totalElevationGain,
    required this.startDate,
    this.hasHeartrate = false,
    this.averageHeartrate,
  });

  double get distanceKm => distanceMeters / 1000;
  String get pacePerKm {
    if (averageSpeed <= 0) return '--:--';
    final secsPerKm = 1000 / averageSpeed;
    final mins = secsPerKm ~/ 60;
    final secs = (secsPerKm % 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String get durationFormatted {
    final mins = movingTimeSeconds ~/ 60;
    return '${mins}min';
  }
}

/// Detailed activity data (splits, segments, etc.)
class DetailedStravaActivity {
  final List<SplitData> splits;
  final List<SegmentEffortData> segments;
  final double calories;
  final double maxSpeed;
  final double? averageCadence;
  final double? sufferScore;
  final int prCount;
  final String? deviceName;

  const DetailedStravaActivity({
    required this.splits,
    required this.segments,
    required this.calories,
    required this.maxSpeed,
    this.averageCadence,
    this.sufferScore,
    required this.prCount,
    this.deviceName,
  });
}

class SplitData {
  final int split;
  final double distanceMeters;
  final int movingTimeSeconds;
  final double averageSpeed;
  final double elevationDiff;
  final int paceZone;

  const SplitData({
    required this.split,
    required this.distanceMeters,
    required this.movingTimeSeconds,
    required this.averageSpeed,
    required this.elevationDiff,
    required this.paceZone,
  });

  String get pacePerKm {
    if (averageSpeed <= 0) return '--:--';
    final secsPerKm = 1000 / averageSpeed;
    final mins = secsPerKm ~/ 60;
    final secs = (secsPerKm % 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

class SegmentEffortData {
  final String name;
  final double distanceMeters;
  final int elapsedTimeSeconds;
  final int movingTimeSeconds;
  final int? prRank;
  final int? komRank;
  final double? averageGrade;

  const SegmentEffortData({
    required this.name,
    required this.distanceMeters,
    required this.elapsedTimeSeconds,
    required this.movingTimeSeconds,
    this.prRank,
    this.komRank,
    this.averageGrade,
  });

  String get pacePerKm {
    if (movingTimeSeconds <= 0 || distanceMeters <= 0) return '--:--';
    final secsPerKm = movingTimeSeconds / (distanceMeters / 1000);
    final mins = secsPerKm ~/ 60;
    final secs = (secsPerKm % 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  double get distanceKm => distanceMeters / 1000;
}
