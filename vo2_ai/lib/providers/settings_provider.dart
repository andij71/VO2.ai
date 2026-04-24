// lib/providers/settings_provider.dart

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../data/database.dart';
import 'database_provider.dart';

class UserSetup {
  final String? goal;
  final String? level;
  final int daysPerWeek;
  final List<int> runningDays; // 0=Mon..6=Sun
  final double? weeklyKm; // current weekly volume
  final bool mobility; // includes mobility/strength work
  final bool proNames; // creative session names
  final String accentColor;
  final String aiModel;

  const UserSetup({
    this.goal,
    this.level,
    this.daysPerWeek = 5,
    this.runningDays = const [0, 1, 2, 3, 4], // Mon-Fri default
    this.weeklyKm,
    this.mobility = false,
    this.proNames = true,
    this.accentColor = 'volt',
    this.aiModel = 'google/gemini-2.5-flash-lite',
  });

  UserSetup copyWith({
    String? goal,
    String? level,
    int? daysPerWeek,
    List<int>? runningDays,
    double? weeklyKm,
    bool? mobility,
    bool? proNames,
    String? accentColor,
    String? aiModel,
  }) {
    return UserSetup(
      goal: goal ?? this.goal,
      level: level ?? this.level,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      runningDays: runningDays ?? this.runningDays,
      weeklyKm: weeklyKm ?? this.weeklyKm,
      mobility: mobility ?? this.mobility,
      proNames: proNames ?? this.proNames,
      accentColor: accentColor ?? this.accentColor,
      aiModel: aiModel ?? this.aiModel,
    );
  }

  bool get isComplete => goal != null && level != null;

  /// Display-friendly model name
  String get aiModelLabel {
    final parts = aiModel.split('/');
    return parts.length > 1 ? parts[1] : aiModel;
  }
}

const availableModels = [
  // ('anthropic/claude-sonnet-4', 'Claude Sonnet 4', '\$0.003/1K tokens'),
  // ('anthropic/claude-haiku-4', 'Claude Haiku 4', '\$0.0008/1K tokens'),
  // ('openai/gpt-4o', 'GPT-4o', '\$0.005/1K tokens'),
  // ('openai/gpt-4o-mini', 'GPT-4o Mini', '\$0.0003/1K tokens'),
  ('google/gemini-2.5-flash-lite', 'Gemini 2.5 Flash', '\$0.0003/1K tokens'),
  // ('google/gemma-4-31b-it:free', 'Gemma 4 31B (Free)', 'Free'),
];

class SettingsNotifier extends StateNotifier<UserSetup> {
  final AppDatabase _db;

  SettingsNotifier(this._db) : super(const UserSetup()) {
    _loadProfile();
    _loadModel();
    _loadAccent();
  }

  void setGoal(String goal) => state = state.copyWith(goal: goal);
  void setLevel(String level) => state = state.copyWith(level: level);
  void setDaysPerWeek(int days) => state = state.copyWith(daysPerWeek: days);
  void setRunningDays(List<int> days) => state = state.copyWith(runningDays: days, daysPerWeek: days.length);
  void setWeeklyKm(double km) => state = state.copyWith(weeklyKm: km);
  void setMobility(bool v) => state = state.copyWith(mobility: v);
  void setProNames(bool v) => state = state.copyWith(proNames: v);
  void setAccentColor(String color) {
    state = state.copyWith(accentColor: color);
    _saveAccent(color);
  }

  void setAiModel(String model) {
    state = state.copyWith(aiModel: model);
    _saveModel(model);
  }

  Future<void> _loadProfile() async {
    final users = await _db.select(_db.userProfiles).get();
    if (users.isNotEmpty) {
      final u = users.first;
      state = state.copyWith(
        goal: u.goal,
        level: u.level,
        daysPerWeek: u.daysPerWeek,
      );
    }
  }

  Future<void> _loadModel() async {
    final rows = await (_db.select(_db.settings)
          ..where((t) => t.key.equals('ai_model')))
        .get();
    if (rows.isNotEmpty) {
      state = state.copyWith(aiModel: rows.first.value);
    }
  }

  Future<void> _saveModel(String model) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: 'ai_model', value: model),
        );
  }

  Future<void> _loadAccent() async {
    final rows = await (_db.select(_db.settings)
          ..where((t) => t.key.equals('accent_color')))
        .get();
    if (rows.isNotEmpty) {
      state = state.copyWith(accentColor: rows.first.value);
    }
  }

  Future<void> _saveAccent(String color) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: 'accent_color', value: color),
        );
  }

  /// Reset setup state (clear user profile from DB and memory)
  Future<void> resetSetup() async {
    await _db.delete(_db.userProfiles).go();
    state = const UserSetup();
    // Reload model preference (keep it)
    await _loadModel();
  }

  Future<int> saveProfile(String name) async {
    final id = await _db.into(_db.userProfiles).insert(
          UserProfilesCompanion.insert(
            name: name,
            goal: state.goal!,
            level: state.level!,
            daysPerWeek: Value(state.daysPerWeek),
          ),
        );
    return id;
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSetup>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsNotifier(db);
});

/// Derived provider for the active accent preset
final accentProvider = Provider<AccentPreset>((ref) {
  final setup = ref.watch(settingsProvider);
  return AccentPreset.fromName(setup.accentColor);
});
