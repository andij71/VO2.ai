// test/services/database_test.dart

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('UserProfiles', () {
    test('insert and retrieve user profile', () async {
      final id = await db.into(db.userProfiles).insert(
            UserProfilesCompanion.insert(
              name: 'Alex',
              goal: 'sub20',
              level: 'intermediate',
              daysPerWeek: Value(5),
            ),
          );
      final user = await (db.select(db.userProfiles)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(user.name, 'Alex');
      expect(user.goal, 'sub20');
      expect(user.level, 'intermediate');
      expect(user.daysPerWeek, 5);
    });
  });

  group('TrainingPlans + PlanDays', () {
    test('insert plan with days', () async {
      final userId = await db.into(db.userProfiles).insert(
            UserProfilesCompanion.insert(
              name: 'Alex',
              goal: 'sub20',
              level: 'intermediate',
              daysPerWeek: Value(5),
            ),
          );
      final planId = await db.into(db.trainingPlans).insert(
            TrainingPlansCompanion.insert(
              userId: userId,
              goal: 'sub20',
              level: 'intermediate',
              totalWeeks: 8,
              currentWeek: 1,
            ),
          );
      await db.into(db.planDays).insert(
            PlanDaysCompanion.insert(
              planId: planId,
              week: 1,
              dayOfWeek: 0,
              sessionType: 'easy',
              label: 'Recovery Run',
              distanceKm: 6.4,
              targetPace: '5:45',
              effortZone: 2,
            ),
          );
      final days = await (db.select(db.planDays)
            ..where((t) => t.planId.equals(planId)))
          .get();
      expect(days.length, 1);
      expect(days.first.label, 'Recovery Run');
      expect(days.first.distanceKm, 6.4);
    });
  });

  group('ChatMessages', () {
    test('insert and query messages in order', () async {
      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion.insert(role: 'user', content: 'Hello'),
          );
      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion.insert(
                role: 'assistant', content: 'Hi there!'),
          );
      final msgs = await (db.select(db.chatMessages)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
      expect(msgs.length, 2);
      expect(msgs.first.role, 'user');
      expect(msgs.last.role, 'assistant');
    });
  });
}
