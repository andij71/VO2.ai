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
  final List<String> options;

  const ChatResponse({required this.message, this.actions = const [], this.options = const []});
}

class ChatService {
  static const systemPrompt = '''You are VO2.ai, an expert running coach. You are knowledgeable, encouraging, and concise. Give actionable advice based on the runner's current plan, fitness level, and training context. Keep responses under 3 paragraphs unless the user asks for detail.

LANGUAGE & FORMAT:
- Always reply in the same language the user writes in.
- Use markdown formatting: **bold** for emphasis, bullet lists for structure, headers for sections when needed. Keep it readable on mobile.

PLAN MODIFICATION:
When the user asks to change their training plan, you MUST include a JSON action block at the END of your message inside a fenced code block labeled "actions":

```actions
[{"type": "update_day", "params": {"week": 1, "dayOfWeek": 0, "sessionType": "easy", "label": "Recovery Run", "distanceKm": 5.0, "targetPace": "6:00", "effortZone": 2}}]
```

Action types:
- "update_day": Modify a specific day. Params: week (int), dayOfWeek (0=Mon..6=Sun), plus fields to change: sessionType, label, distanceKm, targetPace, effortZone, notes
- "swap_days": Swap two days. Params: week1, day1, week2, day2
- "rest_day": Convert a day to rest. Params: week (int), dayOfWeek (int)

You can include multiple actions in the array. Always explain what you're changing in plain text BEFORE the action block. If the user is just asking questions, do NOT include an action block.

FOLLOW-UP OPTIONS:
After EVERY response, include 2-3 short follow-up options the user might want to ask next. Place them in a fenced code block labeled "options" at the very end:

```options
["Option 1", "Option 2", "Option 3"]
```

Options should be short (under 8 words), relevant to the conversation, and training-focused. Examples:
- "How should I warm up?"
- "Make it easier this week"
- "What if I feel tired?"
- "Show me alternative paces"
Do NOT suggest options for things the app already handles (changing settings, connecting Strava, switching AI model, changing accent color).''';

  static const _goalNames = {
    'c25k': 'couch to 5K',
    'first5k': 'first 5K',
    'sub20': 'sub-20 minute 5K',
    '10k': '10K',
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
    final now = DateTime.now();
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];
    final buffer = StringBuffer();
    buffer.writeln('Runner context:');
    buffer.writeln('- Today: $weekday, ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
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

  /// Parse AI response — extracts text, plan actions, and follow-up options
  static ChatResponse parseResponse(String raw) {
    debugPrint('[ChatService] Parsing response (${raw.length} chars)');

    var text = raw;
    List<String> options = [];
    List<PlanAction> actions = [];

    // Extract ```options\n[...]\n``` block
    final optionsRegex = RegExp(r'```options?\s*\n([\s\S]*?)\n```');
    final optionsMatch = optionsRegex.firstMatch(text);
    if (optionsMatch != null) {
      try {
        final decoded = jsonDecode(optionsMatch.group(1)!.trim());
        if (decoded is List) {
          options = decoded.cast<String>();
          debugPrint('[ChatService] Found ${options.length} options');
        }
      } catch (e) {
        debugPrint('[ChatService] Failed to parse options: $e');
      }
      text = text.replaceRange(optionsMatch.start, optionsMatch.end, '').trim();
    }

    // Extract ```actions\n[...]\n``` block
    final actionsRegex = RegExp(r'```actions?\s*\n([\s\S]*?)\n```');
    final actionsMatch = actionsRegex.firstMatch(text);
    if (actionsMatch != null) {
      final parsed = _parseActions(actionsMatch.group(1)!.trim());
      if (parsed != null) actions = parsed;
      text = text.substring(0, actionsMatch.start).trim();
    }

    // Fallback: $$$ACTIONS\n[...]\n$$$ format
    if (actions.isEmpty) {
      final dollarRegex = RegExp(r'\$\$\$ACTIONS\s*\n?([\s\S]*?)\n?\$\$\$');
      final dollarMatch = dollarRegex.firstMatch(text);
      if (dollarMatch != null) {
        final parsed = _parseActions(dollarMatch.group(1)!.trim());
        if (parsed != null) actions = parsed;
        text = text.substring(0, dollarMatch.start).trim();
      }
    }

    // Last resort: trailing JSON array with action shape
    if (actions.isEmpty) {
      final lastBracket = text.lastIndexOf(']');
      if (lastBracket != -1) {
        var depth = 0;
        for (var i = lastBracket; i >= 0; i--) {
          if (text[i] == ']') depth++;
          if (text[i] == '[') depth--;
          if (depth == 0) {
            final jsonStr = text.substring(i, lastBracket + 1);
            if (jsonStr.contains('"type"') && jsonStr.contains('"params"')) {
              final parsed = _parseActions(jsonStr);
              if (parsed != null) {
                actions = parsed;
                text = text.substring(0, i).trim();
              }
            }
            break;
          }
        }
      }
    }

    if (actions.isEmpty && options.isEmpty) {
      debugPrint('[ChatService] No actions or options found');
    }

    return ChatResponse(message: text, actions: actions, options: options);
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
        final dow = (day.dayOfWeek as int).clamp(0, 6);
        final name = dayNames[dow];
        buf.writeln('  $name: ${day.sessionType} - ${day.label} (${day.distanceKm}km @ ${day.targetPace}/km)');
      }
    }
    if (weeks.length > 4) {
      buf.writeln('... +${weeks.length - 4} more weeks');
    }
    return buf.toString();
  }
}
