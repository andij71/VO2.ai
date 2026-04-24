// lib/services/chat_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

class PlanAction {
  final String type; // 'update_day', 'swap_days', 'rest_day'
  final Map<String, dynamic> params;

  const PlanAction({required this.type, required this.params});

  factory PlanAction.fromJson(Map<String, dynamic> json) {
    return PlanAction(
      type: json['type'] as String,
      params: json['params'] as Map<String, dynamic>? ?? {},
    );
  }
}

class ChatResponse {
  final String message;
  final List<PlanAction> actions;

  const ChatResponse({required this.message, this.actions = const []});
}

class ChatService {
  static const systemPrompt = '''You are VO2.ai, an expert running coach. You are knowledgeable, encouraging, and concise. Give actionable advice based on the runner's current plan, fitness level, and training context. Keep responses under 3 paragraphs unless the user asks for detail.

PLAN MODIFICATION:
When the user asks to change their training plan, you MUST include a JSON action block at the END of your message inside a fenced code block labeled "actions":

```actions
[{"type": "update_day", "params": {"week": 1, "dayOfWeek": 0, "sessionType": "easy", "label": "Recovery Run", "distanceKm": 5.0, "targetPace": "6:00", "effortZone": 2}}]
```

Action types:
- "update_day": Modify a specific day. Params: week (int), dayOfWeek (0=Mon..6=Sun), plus fields to change: sessionType, label, distanceKm, targetPace, effortZone, notes
- "swap_days": Swap two days. Params: week1, day1, week2, day2
- "rest_day": Convert a day to rest. Params: week (int), dayOfWeek (int)

You can include multiple actions in the array. Always explain what you're changing in plain text BEFORE the action block. If the user is just asking questions, do NOT include an action block.''';

  static const _goalNames = {
    'sub20': 'sub-20 minute 5K',
    'hm': 'half marathon',
    'fm': 'full marathon',
    'speed': '1K speed',
  };

  static String buildContext({
    required String goal,
    required String level,
    required int currentWeek,
    required int totalWeeks,
    String? todaySession,
    String? planSummary,
    String? dayContext,
    String? stravaContext,
  }) {
    final goalName = _goalNames[goal] ?? goal;
    final buffer = StringBuffer();
    buffer.writeln('Runner context:');
    buffer.writeln('- Goal: $goalName');
    buffer.writeln('- Level: $level');
    buffer.writeln('- Progress: Week $currentWeek of $totalWeeks');
    if (todaySession != null) {
      buffer.writeln('- Today\'s session: $todaySession');
    }
    if (planSummary != null) {
      buffer.writeln('\nCurrent plan:\n$planSummary');
    }
    if (stravaContext != null && stravaContext.isNotEmpty) {
      buffer.writeln('\n$stravaContext');
    }
    if (dayContext != null) {
      buffer.writeln('\n$dayContext');
    }
    return buffer.toString();
  }

  static List<Map<String, String>> buildMessages({
    required String systemPrompt,
    required String context,
    required List<Map<String, String>> history,
  }) {
    return [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'system', 'content': context},
      ...history,
    ];
  }

  /// Parse AI response — extracts text and any plan actions from ```actions blocks or $$$ACTIONS blocks
  static ChatResponse parseResponse(String raw) {
    debugPrint('[ChatService] Parsing response (${raw.length} chars)');

    // Try ```actions\n[...]\n``` format
    final codeBlockRegex = RegExp(r'```actions?\s*\n([\s\S]*?)\n```');
    final codeMatch = codeBlockRegex.firstMatch(raw);

    if (codeMatch != null) {
      final jsonStr = codeMatch.group(1)!.trim();
      final message = raw.substring(0, codeMatch.start).trim();
      debugPrint('[ChatService] Found actions code block: $jsonStr');

      final actions = _parseActions(jsonStr);
      if (actions != null) {
        return ChatResponse(message: message, actions: actions);
      }
    }

    // Try $$$ACTIONS\n[...]\n$$$ format (fallback)
    final dollarRegex = RegExp(r'\$\$\$ACTIONS\s*\n?([\s\S]*?)\n?\$\$\$');
    final dollarMatch = dollarRegex.firstMatch(raw);

    if (dollarMatch != null) {
      final jsonStr = dollarMatch.group(1)!.trim();
      final message = raw.substring(0, dollarMatch.start).trim();
      debugPrint('[ChatService] Found \$\$\$ACTIONS block: $jsonStr');

      final actions = _parseActions(jsonStr);
      if (actions != null) {
        return ChatResponse(message: message, actions: actions);
      }
    }

    // Last resort: look for a JSON array at the end of the response
    final lastBracket = raw.lastIndexOf(']');
    if (lastBracket != -1) {
      // Walk backwards to find matching [
      var depth = 0;
      for (var i = lastBracket; i >= 0; i--) {
        if (raw[i] == ']') depth++;
        if (raw[i] == '[') depth--;
        if (depth == 0) {
          final jsonStr = raw.substring(i, lastBracket + 1);
          if (jsonStr.contains('"type"') && jsonStr.contains('"params"')) {
            debugPrint('[ChatService] Found trailing JSON array');
            final actions = _parseActions(jsonStr);
            if (actions != null) {
              final message = raw.substring(0, i).trim();
              return ChatResponse(message: message, actions: actions);
            }
          }
          break;
        }
      }
    }

    debugPrint('[ChatService] No actions found in response');
    return ChatResponse(message: raw.trim());
  }

  static List<PlanAction>? _parseActions(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List && decoded.isNotEmpty) {
        return decoded
            .map((a) => PlanAction.fromJson(a as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[ChatService] Failed to parse actions JSON: $e');
    }
    return null;
  }

  /// Build a short summary of the plan for context injection
  static String buildPlanSummary(List<dynamic> days) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeks = <int, List<dynamic>>{};
    for (final d in days) {
      final week = (d as dynamic).week as int;
      weeks.putIfAbsent(week, () => []).add(d);
    }

    final buf = StringBuffer();
    for (final entry in weeks.entries.take(4)) {
      buf.writeln('Week ${entry.key}:');
      for (final d in entry.value) {
        final day = d as dynamic;
        final name = dayNames[day.dayOfWeek as int];
        buf.writeln('  $name: ${day.sessionType} - ${day.label} (${day.distanceKm}km @ ${day.targetPace}/km)');
      }
    }
    if (weeks.length > 4) {
      buf.writeln('... +${weeks.length - 4} more weeks');
    }
    return buf.toString();
  }
}
