// lib/services/plan_generator_service.dart

import 'dart:convert';
import '../models/plan_day.dart';

class PlanParseException implements Exception {
  final String message;
  PlanParseException(this.message);

  @override
  String toString() => 'PlanParseException: $message';
}

class PlanGeneratorService {
  static const _goalDescriptions = {
    'c25k': 'couch to 5K — complete beginner program with walk/run intervals',
    'first5k': 'first 5K completion — beginner runner building endurance',
    'sub20': 'sub-20 minute 5K',
    '10k': '10K completion or personal record',
    'hm': 'half marathon completion',
    'fm': 'full marathon personal record',
    'speed': '1K time trial personal record',
  };

  static const _totalWeeks = {
    'c25k': 8,
    'first5k': 6,
    'sub20': 8,
    '10k': 8,
    'hm': 12,
    'fm': 16,
    'speed': 6,
  };

  static int weeksForGoal(String goal) => _totalWeeks[goal] ?? 8;

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  static String buildSystemPrompt({
    required String goal,
    required String level,
    required int daysPerWeek,
    List<int> runningDays = const [0, 1, 2, 3, 4],
    double? weeklyKm,
    bool mobility = false,
    bool proNames = true,
  }) {
    final goalDesc = _goalDescriptions[goal] ?? goal;
    final daysList = runningDays.map((d) => _dayNames[d]).join(', ');
    final volumeInfo = weeklyKm != null
        ? '\nCurrent weekly volume: ${weeklyKm.toStringAsFixed(0)} km/week'
        : '';
    final mobilityInfo = mobility
        ? '\nRunner includes mobility/strength work — factor this into recovery planning.'
        : '';
    final now = DateTime.now();
    final todayName = _dayNames[now.weekday - 1];
    final todayDow = now.weekday - 1; // 0=Mon..6=Sun
    return '''You are an expert running coach AI. Generate a structured training plan.

Goal: $goalDesc
Level: $level
Training days: $daysPerWeek days per week ($daysList)
Total weeks: ${_totalWeeks[goal] ?? 8}$volumeInfo$mobilityInfo

Today is $todayName (dayOfWeek=$todayDow). Week 1 starts TODAY — only include days from today ($todayName) onwards in week 1. Do NOT include days before today in week 1.

Return ONLY a JSON array of training day objects. No explanation, no markdown.

CRITICAL RULES:
- Generate ALL 7 days per week (dayOfWeek 0–6). Every day must have an entry.
- Week 1 starts at dayOfWeek=$todayDow ($todayName). Skip days 0–${todayDow > 0 ? todayDow - 1 : 'none'} in week 1.
- Generate EXACTLY ONE entry per (week, dayOfWeek) pair. Never duplicate.
- Running sessions ONLY on these dayOfWeek values: ${runningDays.join(', ')} ($daysList). These are AVAILABLE for training, not all must be hard sessions — use easy/recovery runs on some.
- ALL other dayOfWeek values MUST be rest days (sessionType="rest", distanceKm=0, targetPace="—", effortZone=0).
- Each day gets EITHER a training session OR a rest day, NEVER both.

Each object must have these exact fields:
- "week": int (1-indexed)
- "dayOfWeek": int (0=Monday, 6=Sunday)
- "sessionType": string ("easy", "tempo", "long", "rest", "interval")
- "label": string (${proNames ? 'creative, energetic session name — e.g. "Threshold Surge", "Recovery Cruise", "Endurance Engine", "Speed Demon"' : 'descriptive session name — e.g. "Easy Run", "Tempo Run", "Long Run"'})
- "distanceKm": number (0 for rest days)
- "targetPace": string (e.g. "5:30" in min/km, or "—" for rest)
- "effortZone": int (1-5, 0 for rest)
- "notes": string or null

Build a progressive, periodized plan that increases load gradually with recovery weeks.
Adapt intensity and volume to the runner's level.
${proNames ? 'Give each session a distinctive, powered name — avoid generic labels like "Easy Run" or "Long Run". Be creative and motivating.' : 'Use clear, descriptive session names.'}''';
  }

  static List<PlanDayModel> parsePlanJson(String raw) {
    var cleaned = raw.trim();

    debugLog('Raw response length: ${raw.length} chars');
    debugLog(
        'First 200 chars: ${raw.substring(0, raw.length < 200 ? raw.length : 200)}');
    debugLog(
        'Last 200 chars: ${raw.substring(raw.length < 200 ? 0 : raw.length - 200)}');

    // Strip markdown code fences
    if (cleaned.startsWith('```')) {
      debugLog('Stripping markdown code fences');
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```\s*$'), '');
    }

    debugLog('Cleaned length: ${cleaned.length} chars');

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) {
        throw PlanParseException(
            'Expected JSON array, got ${decoded.runtimeType}');
      }
      debugLog('Parsed ${decoded.length} plan day entries');
      return decoded
          .map((e) => PlanDayModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      debugLog('JSON parse failed, attempting repair...');
      final repaired = _repairJson(cleaned);
      try {
        final decoded = jsonDecode(repaired);
        if (decoded is! List) {
          throw PlanParseException(
              'Expected JSON array after repair, got ${decoded.runtimeType}');
        }
        debugLog('Repair succeeded: ${decoded.length} plan day entries');
        return decoded
            .map((e) => PlanDayModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } on FormatException catch (e2) {
        debugLog('Repair also failed: ${e2.message}');
        debugLog('Full cleaned response:\n$cleaned');
        throw PlanParseException('Invalid JSON: ${e2.message}');
      }
    }
  }

  /// Attempts to repair truncated JSON arrays from LLM responses.
  /// Handles: unterminated strings, missing closing braces/brackets,
  /// trailing commas, and partial objects.
  static String _repairJson(String json) {
    var s = json.trim();

    // Find the last complete object (ending with '}')
    final lastCloseBrace = s.lastIndexOf('}');
    if (lastCloseBrace == -1) {
      debugLog('Repair: no complete object found');
      return s;
    }

    // Truncate to the last complete object
    s = s.substring(0, lastCloseBrace + 1);

    // Remove any trailing comma after the last object
    s = s.trimRight();
    if (s.endsWith(',')) {
      s = s.substring(0, s.length - 1);
    }

    // Count unmatched brackets and braces, close them
    int brackets = 0;
    int braces = 0;
    bool inString = false;
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '"' && (i == 0 || s[i - 1] != '\\')) {
        inString = !inString;
      }
      if (!inString) {
        if (c == '[') brackets++;
        if (c == ']') brackets--;
        if (c == '{') braces++;
        if (c == '}') braces--;
      }
    }

    // Close any unclosed braces/brackets
    for (int i = 0; i < braces; i++) {
      s += '}';
    }
    for (int i = 0; i < brackets; i++) {
      s += ']';
    }

    debugLog(
        'Repair: truncated at last complete object, added $braces } and $brackets ]');
    return s;
  }

  /// Ensure all 7 days per week exist, enforce running days, remove pre-today in week 1.
  static List<PlanDayModel> cleanupDays(List<PlanDayModel> days,
      {required List<int> runningDays}) {
    final todayDow = DateTime.now().weekday - 1; // 0=Mon..6=Sun

    // Remove pre-today days in week 1
    days = days.where((d) => d.week > 1 || d.dayOfWeek >= todayDow).toList();

    // Enforce running days: non-running days become rest
    days = days.map((d) {
      final isRunningDay = runningDays.contains(d.dayOfWeek);
      if (!isRunningDay && d.sessionType != 'rest') {
        debugLog(
            'Forcing rest on non-running day: week=${d.week} dow=${d.dayOfWeek}');
        return PlanDayModel(
          week: d.week,
          dayOfWeek: d.dayOfWeek,
          sessionType: 'rest',
          label: 'Rest Day',
          distanceKm: 0,
          targetPace: '\u2014',
          effortZone: 0,
          notes: null,
        );
      }
      return d;
    }).toList();

    days = deduplicateDays(days);

    // Fill missing days so every week has all 7 (or from today for week 1)
    final weeks = <int>{};
    for (final d in days) {
      weeks.add(d.week);
    }
    if (weeks.isEmpty) return days;

    final maxWeek = weeks.reduce((a, b) => a > b ? a : b);
    final existing = <String>{};
    for (final d in days) {
      existing.add('${d.week}-${d.dayOfWeek}');
    }

    for (var w = 1; w <= maxWeek; w++) {
      final startDow = (w == 1) ? todayDow : 0;
      for (var dow = startDow; dow < 7; dow++) {
        final key = '$w-$dow';
        if (!existing.contains(key)) {
          days.add(PlanDayModel(
            week: w,
            dayOfWeek: dow,
            sessionType: 'rest',
            label: 'Rest Day',
            distanceKm: 0,
            targetPace: '\u2014',
            effortZone: 0,
            notes: null,
          ));
        }
      }
    }

    // Re-sort after filling
    days.sort((a, b) {
      final w = a.week.compareTo(b.week);
      return w != 0 ? w : a.dayOfWeek.compareTo(b.dayOfWeek);
    });

    debugLog('After fill: ${days.length} days across $maxWeek weeks');
    return days;
  }

  /// Remove duplicate (week, dayOfWeek) entries — keep training over rest.
  static List<PlanDayModel> deduplicateDays(List<PlanDayModel> days) {
    final map = <String, PlanDayModel>{};
    for (final day in days) {
      final key = '${day.week}-${day.dayOfWeek}';
      final existing = map[key];
      if (existing == null) {
        map[key] = day;
      } else {
        // Keep the training session, drop the rest day
        if (existing.sessionType == 'rest' && day.sessionType != 'rest') {
          map[key] = day;
        }
        // If both are training, keep the first one
      }
    }
    final result = map.values.toList()
      ..sort((a, b) {
        final w = a.week.compareTo(b.week);
        return w != 0 ? w : a.dayOfWeek.compareTo(b.dayOfWeek);
      });
    debugLog('Dedup: ${days.length} → ${result.length} days');
    return result;
  }

  /// Build a prompt to assess if the goal is realistic given Strava data.
  static String buildFeasibilityPrompt({
    required String goal,
    required String level,
    required int daysPerWeek,
    required String stravaContext,
  }) {
    final goalDesc = _goalDescriptions[goal] ?? goal;
    return '''You are an expert running coach. Based on the runner's recent training data, assess whether their goal is realistic.

Goal: $goalDesc
Self-assessed level: $level
Planned training days: $daysPerWeek/week

$stravaContext

Respond in this exact JSON format (no markdown, no explanation):
{"feasible": true/false, "message": "2-3 sentence assessment. Be honest but encouraging. If not feasible, explain why and suggest what would be more realistic."}''';
  }

  static void debugLog(String msg) {
    // ignore: avoid_print
    print('[PlanParser] $msg');
  }
}
