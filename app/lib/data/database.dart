// lib/data/database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get goal => text()();
  TextColumn get level => text()();
  IntColumn get daysPerWeek => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TrainingPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(UserProfiles, #id)();
  TextColumn get goal => text()();
  TextColumn get level => text()();
  IntColumn get totalWeeks => integer()();
  IntColumn get currentWeek => integer()();
  DateTimeColumn get startDate => dateTime().nullable()();
  // Generation parameters (stored for reference)
  TextColumn get runningDays => text().withDefault(
      const Constant('0,1,2,3,4'))(); // comma-separated day indices
  RealColumn get weeklyKm => real().nullable()();
  BoolColumn get mobility => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class PlanDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().references(TrainingPlans, #id)();
  IntColumn get week => integer()();
  IntColumn get dayOfWeek => integer()();
  TextColumn get sessionType => text()();
  TextColumn get label => text()();
  RealColumn get distanceKm => real()();
  TextColumn get targetPace => text()();
  IntColumn get effortZone => integer()();
  TextColumn get notes => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  UserProfiles,
  TrainingPlans,
  PlanDays,
  ChatMessages,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.defaults() {
    return AppDatabase(_openConnection());
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await customStatement(
              'ALTER TABLE training_plans ADD COLUMN start_date INTEGER',
            );
          }
          if (from < 3) {
            await customStatement(
              "ALTER TABLE training_plans ADD COLUMN running_days TEXT NOT NULL DEFAULT '0,1,2,3,4'",
            );
            await customStatement(
              'ALTER TABLE training_plans ADD COLUMN weekly_km REAL',
            );
            await customStatement(
              'ALTER TABLE training_plans ADD COLUMN mobility INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
