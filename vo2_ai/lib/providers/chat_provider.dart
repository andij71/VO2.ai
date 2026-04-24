// lib/providers/chat_provider.dart

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../services/chat_service.dart';
import '../services/openrouter_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'plan_provider.dart';
import 'settings_provider.dart';
import 'strava_provider.dart';

Future<void> saveMessage(AppDatabase db,
    {required String role, required String content}) async {
  await db.into(db.chatMessages).insert(
        ChatMessagesCompanion.insert(role: role, content: content),
      );
}

Future<List<Map<String, String>>> loadHistory(AppDatabase db) async {
  final msgs = await (db.select(db.chatMessages)
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();
  return msgs.map((m) => {'role': m.role, 'content': m.content}).toList();
}

class ChatMessage {
  final String role;
  final String content;
  final bool isLoading;
  final bool hasPlanChange;
  final List<PlanActionSummary> planActions;

  const ChatMessage({
    required this.role,
    required this.content,
    this.isLoading = false,
    this.hasPlanChange = false,
    this.planActions = const [],
  });
}

class PlanActionSummary {
  final String type;
  final String description;
  final String icon;

  const PlanActionSummary({required this.type, required this.description, required this.icon});

  static List<PlanActionSummary> fromActions(List<PlanAction> actions) {
    return actions.map((a) {
      switch (a.type) {
        case 'update_day':
          final w = a.params['week'] ?? '?';
          final d = a.params['dayOfWeek'] ?? '?';
          final label = a.params['label'] ?? a.params['sessionType'] ?? 'session';
          return PlanActionSummary(type: 'update', description: 'Week $w, Day $d → $label', icon: '✏️');
        case 'swap_days':
          final w1 = a.params['week1'] ?? '?';
          final d1 = a.params['day1'] ?? '?';
          final w2 = a.params['week2'] ?? '?';
          final d2 = a.params['day2'] ?? '?';
          return PlanActionSummary(type: 'swap', description: 'Swapped W$w1/D$d1 ↔ W$w2/D$d2', icon: '🔄');
        case 'rest_day':
          final w = a.params['week'] ?? '?';
          final d = a.params['dayOfWeek'] ?? '?';
          return PlanActionSummary(type: 'rest', description: 'Week $w, Day $d → Rest Day', icon: '😴');
        default:
          return PlanActionSummary(type: a.type, description: a.type, icon: '⚡');
      }
    }).toList();
  }
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final AppDatabase _db;
  final OpenRouterService? _ai;
  final UserSetup _setup;
  final Ref _ref;

  ChatNotifier(this._db, this._ai, this._setup, this._ref)
      : super([]);

  Future<void> clearChat() async {
    await _db.delete(_db.chatMessages).go();
    if (!mounted) return;
    state = [];
  }

  Future<void> loadMessages() async {
    final history = await loadHistory(_db);
    if (!mounted) return;
    state = history
        .map((m) => ChatMessage(role: m['role']!, content: m['content']!))
        .toList();
  }

  Future<void> sendMessage(String content, {PlanDay? pinnedDay}) async {
    if (_ai == null) return;

    state = [...state, ChatMessage(role: 'user', content: content)];
    await saveMessage(_db, role: 'user', content: content);

    state = [
      ...state,
      const ChatMessage(role: 'assistant', content: '', isLoading: true)
    ];

    try {
      // Read fresh plan status (not cached) so pinned day context is accurate
      final livePlan = _ref.read(planProvider);

      // Build context with current plan summary
      String? planSummary;
      if (livePlan.days != null && livePlan.days!.isNotEmpty) {
        planSummary = ChatService.buildPlanSummary(livePlan.days!);
      }

      String? dayContext;
      if (pinnedDay != null) {
        final d = pinnedDay;
        dayContext = 'PINNED SESSION CONTEXT (user is asking about this specific day):\n'
            'Week ${d.week}, Day ${d.dayOfWeek} — ${d.label}\n'
            'Type: ${d.sessionType}, Distance: ${d.distanceKm}km, '
            'Pace: ${d.targetPace}/km, Zone: ${d.effortZone}'
            '${d.notes != null ? '\nNotes: ${d.notes}' : ''}';
      }

      // Derive week info from plan
      final days = livePlan.days;
      final totalWeeks = days != null && days.isNotEmpty
          ? days.map((d) => d.week).reduce((a, b) => a > b ? a : b)
          : 8;

      // Compute current week from plan's startDate
      var currentWeek = 1;
      if (livePlan.planId != null) {
        final plans = await (_db.select(_db.trainingPlans)
              ..where((t) => t.id.equals(livePlan.planId!)))
            .get();
        if (plans.isNotEmpty && plans.first.startDate != null) {
          final elapsed = DateTime.now().difference(plans.first.startDate!);
          currentWeek = (elapsed.inDays ~/ 7) + 1;
          if (currentWeek < 1) currentWeek = 1;
          if (currentWeek > totalWeeks) currentWeek = totalWeeks;
        }
      }

      // Get Strava activity summary for context
      final stravaStatus = _ref.read(stravaProvider);
      final stravaContext = stravaStatus.aiSummary;

      final context = ChatService.buildContext(
        goal: _setup.goal ?? 'sub20',
        level: _setup.level ?? 'intermediate',
        currentWeek: currentWeek,
        totalWeeks: totalWeeks,
        planSummary: planSummary,
        dayContext: dayContext,
        stravaContext: stravaContext,
      );

      final history = state
          .where((m) => !m.isLoading)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final messages = ChatService.buildMessages(
        systemPrompt: ChatService.systemPrompt,
        context: context,
        history: history,
      );

      final rawResponse = await _ai.sendMessage(
        messages: messages,
        model: _setup.aiModel,
      );

      // Parse response for plan actions
      final parsed = ChatService.parseResponse(rawResponse);
      final hasActions = parsed.actions.isNotEmpty;

      // Apply plan modifications if any
      if (hasActions && livePlan.planId != null) {
        await _applyPlanActions(parsed.actions, livePlan.planId!);
        debugPrint(
            '[ChatProvider] Applied ${parsed.actions.length} plan actions');
      }

      // Save the clean message (without action JSON) to DB
      await saveMessage(_db, role: 'assistant', content: parsed.message);

      if (!mounted) return;
      final actionSummaries = hasActions
          ? PlanActionSummary.fromActions(parsed.actions)
          : <PlanActionSummary>[];

      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(
          role: 'assistant',
          content: parsed.message,
          hasPlanChange: hasActions,
          planActions: actionSummaries,
        ),
      ];

      // Reload the plan if we made changes
      if (hasActions) {
        _ref.read(planProvider.notifier).loadExistingPlan();
      }
    } catch (e, stack) {
      debugPrint('[ChatProvider] Error: $e');
      debugPrint('[ChatProvider] Stack: $stack');
      if (!mounted) return;
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(role: 'assistant', content: 'Error: $e'),
      ];
    }
  }

  Future<void> _applyPlanActions(List<PlanAction> actions, int planId) async {
    for (final action in actions) {
      try {
        switch (action.type) {
          case 'update_day':
            await _updateDay(planId, action.params);
          case 'swap_days':
            await _swapDays(planId, action.params);
          case 'rest_day':
            await _makeRestDay(planId, action.params);
          default:
            debugPrint('[ChatProvider] Unknown action type: ${action.type}');
        }
      } catch (e) {
        debugPrint('[ChatProvider] Failed to apply action ${action.type}: $e');
      }
    }
  }

  Future<void> _updateDay(int planId, Map<String, dynamic> params) async {
    final week = params['week'] as int;
    final dow = params['dayOfWeek'] as int;

    debugPrint('[ChatProvider] Updating day: week=$week dow=$dow');

    final days = await (_db.select(_db.planDays)
          ..where((t) =>
              t.planId.equals(planId) &
              t.week.equals(week) &
              t.dayOfWeek.equals(dow)))
        .get();

    if (days.isEmpty) {
      debugPrint('[ChatProvider] Day not found: week=$week dow=$dow');
      return;
    }

    final dayId = days.first.id;
    await (_db.update(_db.planDays)..where((t) => t.id.equals(dayId))).write(
      PlanDaysCompanion(
        sessionType: params.containsKey('sessionType')
            ? Value(params['sessionType'] as String)
            : const Value.absent(),
        label: params.containsKey('label')
            ? Value(params['label'] as String)
            : const Value.absent(),
        distanceKm: params.containsKey('distanceKm')
            ? Value((params['distanceKm'] as num).toDouble())
            : const Value.absent(),
        targetPace: params.containsKey('targetPace')
            ? Value(params['targetPace'] as String)
            : const Value.absent(),
        effortZone: params.containsKey('effortZone')
            ? Value(params['effortZone'] as int)
            : const Value.absent(),
        notes: params.containsKey('notes')
            ? Value(params['notes'] as String?)
            : const Value.absent(),
      ),
    );
  }

  Future<void> _swapDays(int planId, Map<String, dynamic> params) async {
    final w1 = params['week1'] as int;
    final d1 = params['day1'] as int;
    final w2 = params['week2'] as int;
    final d2 = params['day2'] as int;

    debugPrint('[ChatProvider] Swapping: w$w1/d$d1 <-> w$w2/d$d2');

    final days1 = await (_db.select(_db.planDays)
          ..where((t) =>
              t.planId.equals(planId) &
              t.week.equals(w1) &
              t.dayOfWeek.equals(d1)))
        .get();
    final days2 = await (_db.select(_db.planDays)
          ..where((t) =>
              t.planId.equals(planId) &
              t.week.equals(w2) &
              t.dayOfWeek.equals(d2)))
        .get();

    if (days1.isEmpty || days2.isEmpty) return;

    final a = days1.first;
    final b = days2.first;

    await (_db.update(_db.planDays)..where((t) => t.id.equals(a.id))).write(
      PlanDaysCompanion(
        sessionType: Value(b.sessionType),
        label: Value(b.label),
        distanceKm: Value(b.distanceKm),
        targetPace: Value(b.targetPace),
        effortZone: Value(b.effortZone),
        notes: Value(b.notes),
      ),
    );

    await (_db.update(_db.planDays)..where((t) => t.id.equals(b.id))).write(
      PlanDaysCompanion(
        sessionType: Value(a.sessionType),
        label: Value(a.label),
        distanceKm: Value(a.distanceKm),
        targetPace: Value(a.targetPace),
        effortZone: Value(a.effortZone),
        notes: Value(a.notes),
      ),
    );
  }

  Future<void> _makeRestDay(int planId, Map<String, dynamic> params) async {
    final week = params['week'] as int;
    final dow = params['dayOfWeek'] as int;

    debugPrint('[ChatProvider] Making rest day: week=$week dow=$dow');

    final days = await (_db.select(_db.planDays)
          ..where((t) =>
              t.planId.equals(planId) &
              t.week.equals(week) &
              t.dayOfWeek.equals(dow)))
        .get();

    if (days.isEmpty) return;

    await (_db.update(_db.planDays)..where((t) => t.id.equals(days.first.id)))
        .write(
      const PlanDaysCompanion(
        sessionType: Value('rest'),
        label: Value('Rest Day'),
        distanceKm: Value(0),
        targetPace: Value('\u2014'),
        effortZone: Value(0),
        notes: Value('Coach adjusted: rest day'),
      ),
    );
  }
}

/// Pinned day context for chat — set from plan screen, cleared on dismiss
final chatPinnedDayProvider = StateProvider<PlanDay?>((ref) => null);

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.read(authProvider.notifier);
  final setup = ref.watch(settingsProvider);
  return ChatNotifier(db, auth.service, setup, ref);
});
