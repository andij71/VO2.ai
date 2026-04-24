// test/providers/plan_provider_test.dart

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/database.dart';
import 'package:app/models/plan_day.dart';
import 'package:app/providers/plan_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => await db.close());

  test('savePlanToDb stores all days', () async {
    final userId = await db.into(db.userProfiles).insert(
          UserProfilesCompanion.insert(
              name: 'Test',
              goal: 'sub20',
              level: 'intermediate',
              daysPerWeek: const Value(5)),
        );

    final days = [
      PlanDayModel(
          week: 1,
          dayOfWeek: 0,
          sessionType: 'easy',
          label: 'Easy Run',
          distanceKm: 5.0,
          targetPace: '6:00',
          effortZone: 2),
      PlanDayModel(
          week: 1,
          dayOfWeek: 2,
          sessionType: 'tempo',
          label: 'Tempo',
          distanceKm: 8.0,
          targetPace: '4:55',
          effortZone: 4),
    ];

    final planId = await savePlanToDb(db,
        userId: userId,
        goal: 'sub20',
        level: 'intermediate',
        totalWeeks: 8,
        days: days);

    final stored = await (db.select(db.planDays)
          ..where((t) => t.planId.equals(planId)))
        .get();
    expect(stored.length, 2);
    expect(stored[0].label, 'Easy Run');
    expect(stored[1].sessionType, 'tempo');
  });
}
