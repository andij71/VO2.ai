// lib/providers/plan_provider.dart

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../models/plan_day.dart';
import '../services/openrouter_service.dart';
import '../services/plan_generator_service.dart';
import '../services/strava_service.dart' show StravaActivity, StravaService;
import 'auth_provider.dart';
import 'database_provider.dart';
import 'settings_provider.dart';
import 'strava_provider.dart';

enum PlanState { idle, generating, ready, error }

class PlanStatus {
  final PlanState state;
  final String? errorMessage;
  final int? planId;
  final List<PlanDay>? days;
  final DateTime? startDate;

  const PlanStatus(
      {this.state = PlanState.idle, this.errorMessage, this.planId, this.days, this.startDate});
}

Future<int> savePlanToDb(
  AppDatabase db, {
  required int userId,
  required String goal,
  required String level,
  required int totalWeeks,
  required List<PlanDayModel> days,
  List<int> runningDays = const [0, 1, 2, 3, 4],
  double? weeklyKm,
  bool mobility = false,
}) async {
  // Start date = Monday of current week
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final startDate = DateTime(monday.year, monday.month, monday.day);

  final planId = await db.into(db.trainingPlans).insert(
        TrainingPlansCompanion.insert(
          userId: userId,
          goal: goal,
          level: level,
          totalWeeks: totalWeeks,
          currentWeek: 1,
          startDate: Value(startDate),
          runningDays: Value(runningDays.join(',')),
          weeklyKm: Value(weeklyKm),
          mobility: Value(mobility),
        ),
      );
  for (final day in days) {
    await db.into(db.planDays).insert(
          PlanDaysCompanion.insert(
            planId: planId,
            week: day.week,
            dayOfWeek: day.dayOfWeek,
            sessionType: day.sessionType,
            label: day.label,
            distanceKm: day.distanceKm,
            targetPace: day.targetPace,
            effortZone: day.effortZone,
            notes: Value(day.notes),
          ),
        );
  }
  return planId;
}

class PlanNotifier extends StateNotifier<PlanStatus> {
  final AppDatabase _db;
  final Ref _ref;

  PlanNotifier(this._db, this._ref) : super(const PlanStatus());

  OpenRouterService? get _ai => _ref.read(authProvider.notifier).service;
  UserSetup get _setup => _ref.read(settingsProvider);
  String get _stravaContext => StravaService.summarizeForAI(_ref.read(stravaProvider).activities);

  Future<void> generatePlan() async {
    if (_ai == null) {
      debugPrint('[PlanProvider] No AI service — not authenticated');
      state = const PlanStatus(state: PlanState.error, errorMessage: 'Not connected to OpenRouter');
      return;
    }
    if (!_setup.isComplete) {
      debugPrint('[PlanProvider] Setup incomplete: goal=${_setup.goal} level=${_setup.level}');
      state = const PlanStatus(state: PlanState.error, errorMessage: 'Please complete goal setup first');
      return;
    }

    state = const PlanStatus(state: PlanState.generating);

    try {
      // First try loading an existing plan from DB
      final existingPlans = await (_db.select(_db.trainingPlans)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .get();

      if (existingPlans.isNotEmpty) {
        debugPrint('[PlanProvider] Found existing plan id=${existingPlans.first.id}, loading...');
        final plan = existingPlans.first;
        final storedDays = await (_db.select(_db.planDays)
              ..where((t) => t.planId.equals(plan.id))
              ..orderBy([
                (t) => OrderingTerm.asc(t.week),
                (t) => OrderingTerm.asc(t.dayOfWeek)
              ]))
            .get();

        if (storedDays.isNotEmpty) {
          if (!mounted) return;
          state = PlanStatus(state: PlanState.ready, planId: plan.id, days: storedDays, startDate: plan.startDate);
          return;
        }
      }

      debugPrint('[PlanProvider] Generating new plan: goal=${_setup.goal} level=${_setup.level}');

      final systemPrompt = PlanGeneratorService.buildSystemPrompt(
        goal: _setup.goal!,
        level: _setup.level!,
        daysPerWeek: _setup.daysPerWeek,
        runningDays: _setup.runningDays,
        weeklyKm: _setup.weeklyKm,
        mobility: _setup.mobility,
        proNames: _setup.proNames,
      );

      final userMessage = _stravaContext.isNotEmpty
          ? 'Here is my recent training data from Strava:\n\n$_stravaContext\n\nGenerate my training plan based on this data.'
          : 'Generate my training plan now.';

      debugPrint('[PlanProvider] Strava context: ${_stravaContext.isNotEmpty ? '${_stravaContext.length} chars' : 'none'}');

      final response = await _ai!.sendMessage(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        model: _setup.aiModel,
      );

      debugPrint('[PlanProvider] Got response, parsing JSON...');
      final days = PlanGeneratorService.parsePlanJson(response);
      debugPrint('[PlanProvider] Parsed ${days.length} days');
      final totalWeeks = PlanGeneratorService.weeksForGoal(_setup.goal!);

      // Save to DB (userId=1 for MVP single user)
      // Check if user exists, if not create one
      var users = await _db.select(_db.userProfiles).get();
      int userId;
      if (users.isEmpty) {
        userId = await _db.into(_db.userProfiles).insert(
              UserProfilesCompanion.insert(
                name: 'Runner',
                goal: _setup.goal!,
                level: _setup.level!,
                daysPerWeek: Value(_setup.daysPerWeek),
              ),
            );
      } else {
        userId = users.first.id;
      }

      final planId = await savePlanToDb(
        _db,
        userId: userId,
        goal: _setup.goal!,
        level: _setup.level!,
        totalWeeks: totalWeeks,
        days: days,
        runningDays: _setup.runningDays,
        weeklyKm: _setup.weeklyKm,
        mobility: _setup.mobility,
      );

      final storedDays = await (_db.select(_db.planDays)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.week),
              (t) => OrderingTerm.asc(t.dayOfWeek)
            ]))
          .get();

      if (!mounted) return;
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final planStart = DateTime(monday.year, monday.month, monday.day);
      state =
          PlanStatus(state: PlanState.ready, planId: planId, days: storedDays, startDate: planStart);
    } catch (e, stack) {
      debugPrint('[PlanProvider] Error generating plan: $e');
      debugPrint('[PlanProvider] Stack: $stack');
      if (!mounted) return;
      state = PlanStatus(state: PlanState.error, errorMessage: e.toString());
    }
  }

  Future<void> loadExistingPlan() async {
    final plans = await (_db.select(_db.trainingPlans)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .get();

    if (plans.isEmpty) return;

    final plan = plans.first;
    final days = await (_db.select(_db.planDays)
          ..where((t) => t.planId.equals(plan.id))
          ..orderBy([
            (t) => OrderingTerm.asc(t.week),
            (t) => OrderingTerm.asc(t.dayOfWeek)
          ]))
        .get();

    if (!mounted) return;
    state = PlanStatus(state: PlanState.ready, planId: plan.id, days: days, startDate: plan.startDate);
  }

  /// Match Strava activities to plan days and mark as completed
  Future<int> syncWithStrava(List<StravaActivity> activities) async {
    if (state.planId == null || state.days == null) return 0;

    // Get plan start date
    final plans = await (_db.select(_db.trainingPlans)
          ..where((t) => t.id.equals(state.planId!)))
        .get();
    if (plans.isEmpty || plans.first.startDate == null) return 0;

    final startDate = plans.first.startDate!;
    var matched = 0;

    for (final day in state.days!) {
      if (day.completed || day.sessionType == 'rest') continue;

      // Calculate the actual date of this plan day
      final dayDate = startDate.add(Duration(days: (day.week - 1) * 7 + day.dayOfWeek));
      final dayDateOnly = DateTime(dayDate.year, dayDate.month, dayDate.day);

      // Find a matching Strava activity on the same date
      final match = activities.where((a) {
        final aDate = DateTime(a.startDate.year, a.startDate.month, a.startDate.day);
        return aDate == dayDateOnly;
      }).toList();

      if (match.isNotEmpty) {
        await (_db.update(_db.planDays)..where((t) => t.id.equals(day.id)))
            .write(const PlanDaysCompanion(completed: Value(true)));
        matched++;
      }
    }

    if (matched > 0) {
      debugPrint('[PlanProvider] Synced $matched days from Strava');
      await loadExistingPlan(); // Reload to reflect changes
    }

    return matched;
  }

  Future<void> deletePlan() async {
    if (state.planId == null) return;

    debugPrint('[PlanProvider] Deleting plan id=${state.planId}');

    final planId = state.planId!;
    // Delete plan days first, then the plan
    await (_db.delete(_db.planDays)..where((t) => t.planId.equals(planId))).go();
    await (_db.delete(_db.trainingPlans)..where((t) => t.id.equals(planId))).go();

    if (!mounted) return;
    state = const PlanStatus(state: PlanState.idle);
    debugPrint('[PlanProvider] Plan deleted');
  }
}

final planProvider = StateNotifierProvider<PlanNotifier, PlanStatus>((ref) {
  final db = ref.watch(databaseProvider);
  return PlanNotifier(db, ref);
});
