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
    'sub20': 'sub-20 minute 5K',
    'hm': 'half marathon completion',
    'fm': 'full marathon personal record',
    'speed': '1K time trial personal record',
  };

  static const _totalWeeks = {
    'sub20': 8,
    'hm': 12,
    'fm': 16,
    'speed': 6,
  };

  static int weeksForGoal(String goal) => _totalWeeks[goal] ?? 8;

  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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
    return '''You are an expert running coach AI. Generate a structured training plan.

Goal: $goalDesc
Level: $level
Training days: $daysPerWeek days per week ($daysList)
Total weeks: ${_totalWeeks[goal] ?? 8}$volumeInfo$mobilityInfo

Return ONLY a JSON array of training day objects. No explanation, no markdown.
Each object must have these exact fields:
- "week": int (1-indexed)
- "dayOfWeek": int (0=Monday, 6=Sunday) — schedule runs ONLY on the specified training days, all other days should be rest
- "sessionType": string ("easy", "tempo", "long", "rest", "interval")
- "label": string (${proNames ? 'creative, energetic session name — e.g. "Threshold Surge", "Recovery Cruise", "Endurance Engine", "Speed Demon"' : 'descriptive session name — e.g. "Easy Run", "Tempo Run", "Long Run"'})
- "distanceKm": number (0 for rest days)
- "targetPace": string (e.g. "5:30" in min/km, or "—" for rest)
- "effortZone": int (1-5, 0 for rest)
- "notes": string or null

Build a progressive, periodized plan that increases load gradually with recovery weeks.
Include rest days on non-training days. Adapt intensity and volume to the runner's level.
${proNames ? 'Give each session a distinctive, powered name — avoid generic labels like "Easy Run" or "Long Run". Be creative and motivating.' : 'Use clear, descriptive session names.'}''';
  }

  static List<PlanDayModel> parsePlanJson(String raw) {
    var cleaned = raw.trim();

    debugLog('Raw response length: ${raw.length} chars');
    debugLog('First 200 chars: ${raw.substring(0, raw.length < 200 ? raw.length : 200)}');
    debugLog('Last 200 chars: ${raw.substring(raw.length < 200 ? 0 : raw.length - 200)}');

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
        throw PlanParseException('Expected JSON array, got ${decoded.runtimeType}');
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
          throw PlanParseException('Expected JSON array after repair, got ${decoded.runtimeType}');
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

    debugLog('Repair: truncated at last complete object, added $braces } and $brackets ]');
    return s;
  }

  static void debugLog(String msg) {
    // ignore: avoid_print
    print('[PlanParser] $msg');
  }
}
