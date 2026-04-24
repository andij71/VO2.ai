# vo2 ai MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter mobile app that generates AI-powered running training plans and provides freeform coaching chat via OpenRouter.

**Architecture:** Flutter app with Riverpod state management, Drift (SQLite) for local persistence, direct HTTPS calls to OpenRouter API. No backend server. Dark glass UI ported from RunApp.html prototype.

**Tech Stack:** Flutter 3.x, Dart, Riverpod, Drift, Dio, flutter_secure_storage, go_router

---

## File Structure

```
vo2_ai/
  pubspec.yaml
  lib/
    main.dart                          # Entry point, ProviderScope
    app.dart                           # MaterialApp.router, theme setup

    core/
      theme.dart                       # PaceTheme: dark theme, accent system
      constants.dart                   # Design tokens (colors, radii, durations)

    data/
      database.dart                    # Drift AppDatabase, tables, DAOs
      database.g.dart                  # Generated

    models/
      user_profile.dart                # UserProfile data class
      plan_day.dart                    # PlanDay data class (parsed from DB)

    services/
      openrouter_service.dart          # HTTP client, auth, streaming
      plan_generator_service.dart      # System prompt, JSON parsing
      chat_service.dart                # Context injection, history management

    providers/
      auth_provider.dart               # OpenRouter connection state
      plan_provider.dart               # Current plan, generation state
      chat_provider.dart               # Messages, send/receive
      settings_provider.dart           # User profile, accent color
      database_provider.dart           # DB instance provider

    widgets/
      glass_card.dart                  # Frosted glass container
      accent_pill.dart                 # Colored badge
      spark_line.dart                  # SVG sparkline chart
      ring_chart.dart                  # Circular progress
      loading_orbit.dart               # Orbital loading animation
      pace_button.dart                 # Full-width accent button

    screens/
      welcome_screen.dart              # Splash + Get Started
      auth_screen.dart                 # OpenRouter key input
      goal_setup_screen.dart           # Goal + level wizard
      plan_screen.dart                 # Weekly plan view (home tab)
      chat_screen.dart                 # AI chat
      settings_screen.dart             # Preferences

    router.dart                        # GoRouter config

  test/
    services/
      openrouter_service_test.dart
      plan_generator_service_test.dart
      chat_service_test.dart
    providers/
      plan_provider_test.dart
      chat_provider_test.dart
    widgets/
      glass_card_test.dart
```

---

### Task 1: Project Scaffold

**Files:**
- Create: `vo2_ai/pubspec.yaml`
- Create: `vo2_ai/lib/main.dart`
- Create: `vo2_ai/lib/app.dart`
- Create: `vo2_ai/lib/core/constants.dart`
- Create: `vo2_ai/lib/core/theme.dart`

- [ ] **Step 1: Create Flutter project**

Run:
```bash
cd /Users/aju/git/RunApp
flutter create vo2_ai --org ai.pace --platforms ios,android
```

- [ ] **Step 2: Replace pubspec.yaml dependencies**

```yaml
name: vo2_ai
description: AI Running Coach
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  drift: ^2.22.1
  sqlite3_flutter_libs: ^0.5.28
  path_provider: ^2.1.5
  path: ^1.9.1
  flutter_secure_storage: ^9.2.4
  dio: ^5.7.0
  go_router: ^14.8.1
  url_launcher: ^6.3.1
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  drift_dev: ^2.22.1
  build_runner: ^2.4.14
  riverpod_generator: ^2.6.3
  mockito: ^5.4.5
  build_verify: ^3.1.0

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Install dependencies**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter pub get
```
Expected: "Got dependencies!"

- [ ] **Step 4: Create core/constants.dart**

```dart
// lib/core/constants.dart

import 'dart:ui';

class PaceColors {
  // Backgrounds
  static const background = Color(0xFF080809);
  static const cardBg = Color.fromRGBO(255, 255, 255, 0.055);
  static const cardBorder = Color.fromRGBO(255, 255, 255, 0.12);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color.fromRGBO(255, 255, 255, 0.45);
  static const textTertiary = Color.fromRGBO(255, 255, 255, 0.35);
  static const textMuted = Color.fromRGBO(255, 255, 255, 0.25);

  // Session types
  static const easy = Color(0xFF6BF0A0);
  static const tempo = Color(0xFFFF8C42);
  static const long = Color(0xFFBF5FFF);
  static const rest = Color.fromRGBO(255, 255, 255, 0.25);
  static const interval = Color(0xFF00E5FF);
}

class AccentPreset {
  final Color primary;
  final Color glow;
  final Color dim;

  const AccentPreset({
    required this.primary,
    required this.glow,
    required this.dim,
  });

  static const volt = AccentPreset(
    primary: Color(0xFFC8FF00),
    glow: Color.fromRGBO(200, 255, 0, 0.25),
    dim: Color.fromRGBO(200, 255, 0, 0.1),
  );

  static const violet = AccentPreset(
    primary: Color(0xFFBF5FFF),
    glow: Color.fromRGBO(191, 95, 255, 0.25),
    dim: Color.fromRGBO(191, 95, 255, 0.1),
  );

  static const cyan = AccentPreset(
    primary: Color(0xFF00E5FF),
    glow: Color.fromRGBO(0, 229, 255, 0.25),
    dim: Color.fromRGBO(0, 229, 255, 0.1),
  );
}

class PaceRadii {
  static const card = 24.0;
  static const button = 16.0;
  static const pill = 99.0;
}

class PaceDurations {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 380);
  static const slow = Duration(milliseconds: 450);
}
```

- [ ] **Step 5: Create core/theme.dart**

```dart
// lib/core/theme.dart

import 'package:flutter/material.dart';
import 'constants.dart';

class PaceTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PaceColors.background,
      fontFamily: '.SF Pro Display',
      colorScheme: const ColorScheme.dark(
        surface: PaceColors.background,
        primary: Color(0xFFC8FF00),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: PaceColors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: PaceColors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: PaceColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          color: PaceColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: PaceColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: PaceColors.textTertiary,
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Create main.dart and app.dart**

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: PaceApp()));
}
```

```dart
// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'router.dart';

class PaceApp extends ConsumerWidget {
  const PaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'vo2 ai',
      theme: PaceTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 7: Create minimal router.dart**

```dart
// lib/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('vo2 ai', style: TextStyle(fontSize: 32))),
        ),
      ),
    ],
  );
});
```

- [ ] **Step 8: Verify app builds**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter analyze
```
Expected: "No issues found!"

- [ ] **Step 9: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/
git commit -m "feat: scaffold vo2 ai Flutter project with theme and routing"
```

---

### Task 2: Database Layer (Drift)

**Files:**
- Create: `vo2_ai/lib/data/database.dart`
- Create: `vo2_ai/lib/providers/database_provider.dart`
- Create: `vo2_ai/test/services/database_test.dart`

- [ ] **Step 1: Write database test**

```dart
// test/services/database_test.dart

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vo2_ai/data/database.dart';

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
          daysPerWeek: 5,
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
          name: 'Alex', goal: 'sub20', level: 'intermediate', daysPerWeek: 5,
        ),
      );
      final planId = await db.into(db.trainingPlans).insert(
        TrainingPlansCompanion.insert(
          userId: userId, goal: 'sub20', level: 'intermediate',
          totalWeeks: 8, currentWeek: 1,
        ),
      );
      await db.into(db.planDays).insert(
        PlanDaysCompanion.insert(
          planId: planId, week: 1, dayOfWeek: 0,
          sessionType: 'easy', label: 'Recovery Run',
          distanceKm: 6.4, targetPace: '5:45', effortZone: 2,
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
        ChatMessagesCompanion.insert(role: 'assistant', content: 'Hi there!'),
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
```

- [ ] **Step 2: Create database.dart**

```dart
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
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class TrainingPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(UserProfiles, #id)();
  TextColumn get goal => text()();
  TextColumn get level => text()();
  IntColumn get totalWeeks => integer()();
  IntColumn get currentWeek => integer()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
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
  BoolColumn get completed =>
      boolean().withDefault(const Constant(false))();
}

class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
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
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vo2_ai.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 3: Run code generation**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
dart run build_runner build --delete-conflicting-outputs
```
Expected: generates `database.g.dart`

- [ ] **Step 4: Create database_provider.dart**

```dart
// lib/providers/database_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(() => db.close());
  return db;
});
```

- [ ] **Step 5: Run tests**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/services/database_test.dart -v
```
Expected: All 3 tests pass

- [ ] **Step 6: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/data/ vo2_ai/lib/providers/database_provider.dart vo2_ai/test/services/database_test.dart
git commit -m "feat: add Drift database with tables for users, plans, chat"
```

---

### Task 3: OpenRouter Service

**Files:**
- Create: `vo2_ai/lib/services/openrouter_service.dart`
- Create: `vo2_ai/lib/providers/auth_provider.dart`
- Create: `vo2_ai/test/services/openrouter_service_test.dart`

- [ ] **Step 1: Write OpenRouter service test**

```dart
// test/services/openrouter_service_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vo2_ai/services/openrouter_service.dart';

class MockInterceptor extends Interceptor {
  final List<RequestOptions> requests = [];
  Response? mockResponse;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    if (mockResponse != null) {
      handler.resolve(mockResponse!);
    } else {
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'choices': [
          {'message': {'content': 'Test response'}}
        ]
      }));
    }
  }
}

void main() {
  late OpenRouterService service;
  late MockInterceptor mock;

  setUp(() {
    mock = MockInterceptor();
    final dio = Dio();
    dio.interceptors.add(mock);
    service = OpenRouterService(dio: dio, apiKey: 'test-key');
  });

  test('sendMessage sends correct request format', () async {
    final response = await service.sendMessage(
      messages: [
        {'role': 'user', 'content': 'Hello'}
      ],
      model: 'anthropic/claude-sonnet-4',
    );

    expect(mock.requests.length, 1);
    expect(mock.requests.first.path, contains('/chat/completions'));
    expect(mock.requests.first.headers['Authorization'], 'Bearer test-key');
    final body = mock.requests.first.data as Map<String, dynamic>;
    expect(body['model'], 'anthropic/claude-sonnet-4');
    expect(body['messages'], isA<List>());
    expect(response, 'Test response');
  });

  test('sendMessage throws on error', () async {
    mock.mockResponse = Response(
      requestOptions: RequestOptions(),
      statusCode: 401,
      data: {'error': {'message': 'Invalid API key'}},
    );

    expect(
      () => service.sendMessage(
        messages: [{'role': 'user', 'content': 'Hi'}],
        model: 'anthropic/claude-sonnet-4',
      ),
      throwsA(isA<OpenRouterException>()),
    );
  });

  test('validateKey returns true for valid key', () async {
    final isValid = await service.validateKey();
    expect(isValid, true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/services/openrouter_service_test.dart -v
```
Expected: FAIL — class not found

- [ ] **Step 3: Implement OpenRouter service**

```dart
// lib/services/openrouter_service.dart

import 'package:dio/dio.dart';

class OpenRouterException implements Exception {
  final String message;
  final int? statusCode;
  OpenRouterException(this.message, {this.statusCode});

  @override
  String toString() => 'OpenRouterException: $message (status: $statusCode)';
}

class OpenRouterService {
  static const _baseUrl = 'https://openrouter.ai/api/v1';

  final Dio _dio;
  final String apiKey;

  OpenRouterService({Dio? dio, required this.apiKey})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://pace.ai',
                'X-Title': 'vo2 ai',
              },
            ));

  Future<String> sendMessage({
    required List<Map<String, String>> messages,
    required String model,
  }) async {
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': messages,
      },
    );

    if (response.statusCode != 200) {
      final error = response.data?['error']?['message'] ?? 'Unknown error';
      throw OpenRouterException(error, statusCode: response.statusCode);
    }

    final choices = response.data['choices'] as List;
    if (choices.isEmpty) {
      throw OpenRouterException('No response from model');
    }
    return choices.first['message']['content'] as String;
  }

  Future<bool> validateKey() async {
    try {
      await _dio.get('/models');
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] **Step 4: Run tests**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/services/openrouter_service_test.dart -v
```
Expected: All 3 tests pass

- [ ] **Step 5: Create auth_provider.dart**

```dart
// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/openrouter_service.dart';

const _keyStorageKey = 'openrouter_api_key';

enum AuthState { unknown, unauthenticated, validating, authenticated, invalid }

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  OpenRouterService? _service;

  AuthNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(AuthState.unknown);

  OpenRouterService? get service => _service;

  Future<void> init() async {
    final key = await _storage.read(key: _keyStorageKey);
    if (key == null || key.isEmpty) {
      state = AuthState.unauthenticated;
      return;
    }
    await setKey(key);
  }

  Future<void> setKey(String apiKey) async {
    state = AuthState.validating;
    _service = OpenRouterService(apiKey: apiKey);
    final valid = await _service!.validateKey();
    if (valid) {
      await _storage.write(key: _keyStorageKey, value: apiKey);
      state = AuthState.authenticated;
    } else {
      _service = null;
      state = AuthState.invalid;
    }
  }

  Future<void> clearKey() async {
    await _storage.delete(key: _keyStorageKey);
    _service = null;
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

- [ ] **Step 6: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/services/openrouter_service.dart vo2_ai/lib/providers/auth_provider.dart vo2_ai/test/services/openrouter_service_test.dart
git commit -m "feat: add OpenRouter service with auth provider"
```

---

### Task 4: Plan Generator Service

**Files:**
- Create: `vo2_ai/lib/services/plan_generator_service.dart`
- Create: `vo2_ai/test/services/plan_generator_service_test.dart`

- [ ] **Step 1: Write plan generator test**

```dart
// test/services/plan_generator_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:vo2_ai/services/plan_generator_service.dart';

void main() {
  test('buildSystemPrompt includes goal and level', () {
    final prompt = PlanGeneratorService.buildSystemPrompt(
      goal: 'sub20',
      level: 'intermediate',
      daysPerWeek: 5,
    );
    expect(prompt, contains('sub-20 minute 5K'));
    expect(prompt, contains('intermediate'));
    expect(prompt, contains('5 days per week'));
  });

  test('parsePlanJson extracts valid plan days', () {
    final json = '''
[
  {"week":1,"dayOfWeek":0,"sessionType":"easy","label":"Recovery Run","distanceKm":6.4,"targetPace":"5:45","effortZone":2,"notes":null},
  {"week":1,"dayOfWeek":2,"sessionType":"tempo","label":"Threshold Intervals","distanceKm":8.0,"targetPace":"4:55","effortZone":4,"notes":"3x2km at threshold"}
]
''';
    final days = PlanGeneratorService.parsePlanJson(json);
    expect(days.length, 2);
    expect(days[0].sessionType, 'easy');
    expect(days[0].distanceKm, 6.4);
    expect(days[1].label, 'Threshold Intervals');
    expect(days[1].notes, '3x2km at threshold');
  });

  test('parsePlanJson handles json wrapped in markdown code block', () {
    final json = '''
```json
[{"week":1,"dayOfWeek":0,"sessionType":"easy","label":"Easy Run","distanceKm":5.0,"targetPace":"6:00","effortZone":1,"notes":null}]
```
''';
    final days = PlanGeneratorService.parsePlanJson(json);
    expect(days.length, 1);
    expect(days[0].label, 'Easy Run');
  });

  test('parsePlanJson throws on invalid json', () {
    expect(
      () => PlanGeneratorService.parsePlanJson('not json'),
      throwsA(isA<PlanParseException>()),
    );
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/services/plan_generator_service_test.dart -v
```
Expected: FAIL

- [ ] **Step 3: Create models/plan_day.dart**

```dart
// lib/models/plan_day.dart

class PlanDayModel {
  final int week;
  final int dayOfWeek;
  final String sessionType;
  final String label;
  final double distanceKm;
  final String targetPace;
  final int effortZone;
  final String? notes;

  PlanDayModel({
    required this.week,
    required this.dayOfWeek,
    required this.sessionType,
    required this.label,
    required this.distanceKm,
    required this.targetPace,
    required this.effortZone,
    this.notes,
  });

  factory PlanDayModel.fromJson(Map<String, dynamic> json) {
    return PlanDayModel(
      week: json['week'] as int,
      dayOfWeek: json['dayOfWeek'] as int,
      sessionType: json['sessionType'] as String,
      label: json['label'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      targetPace: json['targetPace'] as String,
      effortZone: json['effortZone'] as int,
      notes: json['notes'] as String?,
    );
  }
}
```

- [ ] **Step 4: Implement plan generator service**

```dart
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

  static String buildSystemPrompt({
    required String goal,
    required String level,
    required int daysPerWeek,
  }) {
    final goalDesc = _goalDescriptions[goal] ?? goal;
    return '''You are an expert running coach AI. Generate a structured training plan.

Goal: $goalDesc
Level: $level
Training days: $daysPerWeek days per week
Total weeks: ${_totalWeeks[goal] ?? 8}

Return ONLY a JSON array of training day objects. No explanation, no markdown.
Each object must have these exact fields:
- "week": int (1-indexed)
- "dayOfWeek": int (0=Monday, 6=Sunday)
- "sessionType": string ("easy", "tempo", "long", "rest", "interval")
- "label": string (human-readable session name)
- "distanceKm": number (0 for rest days)
- "targetPace": string (e.g. "5:30" in min/km, or "—" for rest)
- "effortZone": int (1-5, 0 for rest)
- "notes": string or null

Build a progressive, periodized plan that increases load gradually with recovery weeks.
Include rest days. Adapt intensity and volume to the runner's level.''';
  }

  static List<PlanDayModel> parsePlanJson(String raw) {
    var cleaned = raw.trim();

    // Strip markdown code fences
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```\s*$'), '');
    }

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) {
        throw PlanParseException('Expected JSON array, got ${decoded.runtimeType}');
      }
      return decoded
          .map((e) => PlanDayModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      throw PlanParseException('Invalid JSON: ${e.message}');
    }
  }
}
```

- [ ] **Step 5: Run tests**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/services/plan_generator_service_test.dart -v
```
Expected: All 4 tests pass

- [ ] **Step 6: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/services/plan_generator_service.dart vo2_ai/lib/models/plan_day.dart vo2_ai/test/services/plan_generator_service_test.dart
git commit -m "feat: add plan generator service with prompt building and JSON parsing"
```

---

### Task 5: Chat Service

**Files:**
- Create: `vo2_ai/lib/services/chat_service.dart`
- Create: `vo2_ai/test/services/chat_service_test.dart`

- [ ] **Step 1: Write chat service test**

```dart
// test/services/chat_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:vo2_ai/services/chat_service.dart';

void main() {
  test('buildContext includes plan summary', () {
    final context = ChatService.buildContext(
      goal: 'sub20',
      level: 'intermediate',
      currentWeek: 3,
      totalWeeks: 8,
      todaySession: 'Tempo — 8km at 4:55/km (Zone 4)',
    );
    expect(context, contains('sub-20'));
    expect(context, contains('Week 3 of 8'));
    expect(context, contains('Tempo'));
  });

  test('buildMessages prepends system and context', () {
    final messages = ChatService.buildMessages(
      systemPrompt: 'You are a coach.',
      context: 'Week 3, Tempo day.',
      history: [
        {'role': 'user', 'content': 'How should I warm up?'},
      ],
    );
    expect(messages.length, 3);
    expect(messages[0]['role'], 'system');
    expect(messages[0]['content'], contains('You are a coach'));
    expect(messages[1]['role'], 'system');
    expect(messages[1]['content'], contains('Week 3'));
    expect(messages[2]['role'], 'user');
  });

  test('systemPrompt is concise and defines personality', () {
    final prompt = ChatService.systemPrompt;
    expect(prompt, contains('running coach'));
    expect(prompt.length, lessThan(1000));
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/services/chat_service_test.dart -v
```
Expected: FAIL

- [ ] **Step 3: Implement chat service**

```dart
// lib/services/chat_service.dart

class ChatService {
  static const systemPrompt =
      'You are vo2 ai, an expert running coach. You are knowledgeable, '
      'encouraging, and concise. Give actionable advice based on the runner\'s '
      'current plan, fitness level, and training context. Keep responses under '
      '3 paragraphs unless the user asks for detail.';

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
}
```

- [ ] **Step 4: Run tests**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/services/chat_service_test.dart -v
```
Expected: All 3 tests pass

- [ ] **Step 5: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/services/chat_service.dart vo2_ai/test/services/chat_service_test.dart
git commit -m "feat: add chat service with context building and message formatting"
```

---

### Task 6: Reusable Widgets

**Files:**
- Create: `vo2_ai/lib/widgets/glass_card.dart`
- Create: `vo2_ai/lib/widgets/accent_pill.dart`
- Create: `vo2_ai/lib/widgets/pace_button.dart`
- Create: `vo2_ai/lib/widgets/loading_orbit.dart`
- Create: `vo2_ai/test/widgets/glass_card_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widgets/glass_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vo2_ai/widgets/glass_card.dart';
import 'package:vo2_ai/widgets/accent_pill.dart';
import 'package:vo2_ai/widgets/pace_button.dart';

void main() {
  testWidgets('GlassCard renders child content', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: GlassCard(child: Text('Hello'))),
    ));
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('AccentPill renders label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AccentPill(label: 'EASY')),
    ));
    expect(find.text('EASY'), findsOneWidget);
  });

  testWidgets('PaceButton calls onPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaceButton(
          label: 'Start',
          onPressed: () => pressed = true,
        ),
      ),
    ));
    await tester.tap(find.text('Start'));
    expect(pressed, true);
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/widgets/glass_card_test.dart -v
```
Expected: FAIL

- [ ] **Step 3: Implement glass_card.dart**

```dart
// lib/widgets/glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool glow;
  final Color? glowColor;
  final EdgeInsets? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.glow = false,
    this.glowColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PaceRadii.card),
        border: Border.all(color: PaceColors.cardBorder, width: 0.5),
        boxShadow: [
          if (glow && glowColor != null)
            BoxShadow(color: glowColor!, blurRadius: 40, spreadRadius: -8),
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.35),
            blurRadius: 24,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PaceRadii.card),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: PaceColors.cardBg,
              borderRadius: BorderRadius.circular(PaceRadii.card),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement accent_pill.dart**

```dart
// lib/widgets/accent_pill.dart

import 'package:flutter/material.dart';
import '../core/constants.dart';

class AccentPill extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;

  const AccentPill({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PaceRadii.pill),
        color: backgroundColor ?? const Color.fromRGBO(255, 255, 255, 0.08),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.14),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: color ?? const Color.fromRGBO(255, 255, 255, 0.7),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implement pace_button.dart**

```dart
// lib/widgets/pace_button.dart

import 'package:flutter/material.dart';
import '../core/constants.dart';

class PaceButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? glowColor;
  final bool enabled;

  const PaceButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.glowColor,
    this.enabled = true,
  });

  @override
  State<PaceButton> createState() => _PaceButtonState();
}

class _PaceButtonState extends State<PaceButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AccentPreset.volt.primary;
    final isEnabled = widget.enabled && widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _scale = 0.97) : null,
      onTapUp: isEnabled ? (_) => setState(() => _scale = 1.0) : null,
      onTapCancel: isEnabled ? () => setState(() => _scale = 1.0) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PaceRadii.button),
            color: isEnabled ? accent : const Color.fromRGBO(255, 255, 255, 0.08),
            boxShadow: isEnabled
                ? [BoxShadow(color: widget.glowColor ?? accent.withValues(alpha: 0.25), blurRadius: 24)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: isEnabled ? const Color(0xFF0A0A0C) : PaceColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Implement loading_orbit.dart**

```dart
// lib/widgets/loading_orbit.dart

import 'package:flutter/material.dart';
import '../core/constants.dart';

class LoadingOrbit extends StatefulWidget {
  final Color? color;
  final double size;

  const LoadingOrbit({super.key, this.color, this.size = 80});

  @override
  State<LoadingOrbit> createState() => _LoadingOrbitState();
}

class _LoadingOrbitState extends State<LoadingOrbit>
    with TickerProviderStateMixin {
  late final AnimationController _outer;
  late final AnimationController _inner;

  @override
  void initState() {
    super.initState();
    _outer = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _inner = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _outer.dispose();
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AccentPreset.volt.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          AnimatedBuilder(
            animation: _outer,
            builder: (_, child) => Transform.rotate(
              angle: _outer.value * 2 * 3.14159,
              child: child,
            ),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.1), width: 1.5),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [BoxShadow(color: accent, blurRadius: 12)],
                  ),
                ),
              ),
            ),
          ),
          // Inner ring
          AnimatedBuilder(
            animation: _inner,
            builder: (_, child) => Transform.rotate(
              angle: -_inner.value * 2 * 3.14159,
              child: child,
            ),
            child: Container(
              width: widget.size * 0.65,
              height: widget.size * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.08),
                  width: 1.5,
                ),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8B9EFF),
                    boxShadow: [BoxShadow(color: Color(0xFF8B9EFF), blurRadius: 10)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Run tests**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/widgets/glass_card_test.dart -v
```
Expected: All 3 tests pass

- [ ] **Step 8: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/widgets/ vo2_ai/test/widgets/
git commit -m "feat: add reusable glass UI widgets (card, pill, button, orbit)"
```

---

### Task 7: Welcome & Auth Screens

**Files:**
- Create: `vo2_ai/lib/screens/welcome_screen.dart`
- Create: `vo2_ai/lib/screens/auth_screen.dart`
- Modify: `vo2_ai/lib/router.dart`

- [ ] **Step 1: Implement welcome_screen.dart**

```dart
// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../widgets/pace_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Text(
                'vo2 ai',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AccentPreset.volt.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your AI running coach',
                style: TextStyle(
                  fontSize: 17,
                  color: PaceColors.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              PaceButton(
                label: 'Get Started',
                onPressed: () => context.go('/auth'),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Implement auth_screen.dart**

```dart
// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/pace_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next == AuthState.authenticated) {
        context.go('/setup');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                'Connect AI',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste your OpenRouter API key to power the AI coach.',
                style: TextStyle(fontSize: 14, color: PaceColors.textSecondary),
              ),
              const SizedBox(height: 32),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'sk-or-...',
                      hintStyle: TextStyle(color: PaceColors.textMuted),
                      border: InputBorder.none,
                    ),
                    obscureText: true,
                  ),
                ),
              ),
              if (authState == AuthState.invalid) ...[
                const SizedBox(height: 12),
                const Text(
                  'Invalid API key. Please check and try again.',
                  style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              PaceButton(
                label: authState == AuthState.validating ? 'Validating...' : 'Connect',
                enabled: authState != AuthState.validating,
                onPressed: () {
                  final key = _controller.text.trim();
                  if (key.isNotEmpty) {
                    ref.read(authProvider.notifier).setKey(key);
                  }
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: open openrouter.ai/keys in browser
                  },
                  child: const Text(
                    'Get an API key from OpenRouter',
                    style: TextStyle(color: PaceColors.textSecondary, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Update router.dart**

```dart
// lib/router.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
    ],
  );
});
```

- [ ] **Step 4: Verify app builds**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter analyze
```
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/screens/welcome_screen.dart vo2_ai/lib/screens/auth_screen.dart vo2_ai/lib/router.dart
git commit -m "feat: add welcome and auth screens with OpenRouter key input"
```

---

### Task 8: Goal Setup Screen

**Files:**
- Create: `vo2_ai/lib/screens/goal_setup_screen.dart`
- Create: `vo2_ai/lib/providers/settings_provider.dart`
- Modify: `vo2_ai/lib/router.dart`

- [ ] **Step 1: Create settings_provider.dart**

```dart
// lib/providers/settings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import 'database_provider.dart';

class UserSetup {
  final String? goal;
  final String? level;
  final int daysPerWeek;
  final String accentColor;

  const UserSetup({
    this.goal,
    this.level,
    this.daysPerWeek = 5,
    this.accentColor = 'volt',
  });

  UserSetup copyWith({
    String? goal,
    String? level,
    int? daysPerWeek,
    String? accentColor,
  }) {
    return UserSetup(
      goal: goal ?? this.goal,
      level: level ?? this.level,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  bool get isComplete => goal != null && level != null;
}

class SettingsNotifier extends StateNotifier<UserSetup> {
  final AppDatabase _db;

  SettingsNotifier(this._db) : super(const UserSetup());

  void setGoal(String goal) => state = state.copyWith(goal: goal);
  void setLevel(String level) => state = state.copyWith(level: level);
  void setDaysPerWeek(int days) => state = state.copyWith(daysPerWeek: days);
  void setAccentColor(String color) => state = state.copyWith(accentColor: color);

  Future<int> saveProfile(String name) async {
    final id = await _db.into(_db.userProfiles).insert(
      UserProfilesCompanion.insert(
        name: name,
        goal: state.goal!,
        level: state.level!,
        daysPerWeek: state.daysPerWeek,
      ),
    );
    return id;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSetup>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsNotifier(db);
});
```

- [ ] **Step 2: Implement goal_setup_screen.dart**

```dart
// lib/screens/goal_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/settings_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/pace_button.dart';

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  int _step = 0; // 0=goal, 1=level

  static const _goals = [
    {'id': 'sub20', 'label': 'Sub-20 5K', 'icon': '\u26A1', 'desc': 'Break 4:00/km pace', 'time': '8 weeks'},
    {'id': 'hm', 'label': 'Half Marathon', 'icon': '\uD83C\uDFC3', 'desc': 'Complete 21.1 km', 'time': '12 weeks'},
    {'id': 'fm', 'label': 'Full Marathon', 'icon': '\uD83C\uDFC6', 'desc': '42.2 km PR', 'time': '16 weeks'},
    {'id': 'speed', 'label': 'Speed Builder', 'icon': '\uD83D\uDD25', 'desc': '1K time trial PR', 'time': '6 weeks'},
  ];

  static const _levels = [
    {'id': 'beginner', 'label': 'Beginner', 'desc': '< 20 km/week \u00B7 first structured plan'},
    {'id': 'intermediate', 'label': 'Intermediate', 'desc': '20\u201350 km/week \u00B7 1+ race completed'},
    {'id': 'advanced', 'label': 'Advanced', 'desc': '50+ km/week \u00B7 performance focus'},
  ];

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(settingsProvider);
    final accent = AccentPreset.volt;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'AI COACH',
                style: TextStyle(fontSize: 13, color: PaceColors.textSecondary, letterSpacing: 0.3),
              ),
              const SizedBox(height: 4),
              Text('Build Your Plan', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 20),
              // Step indicator
              Row(
                children: List.generate(2, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: i <= _step ? accent.primary : const Color.fromRGBO(255, 255, 255, 0.12),
                      boxShadow: i <= _step
                          ? [BoxShadow(color: accent.glow, blurRadius: 8)]
                          : null,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _step == 0 ? _buildGoalStep(setup, accent) : _buildLevelStep(setup, accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalStep(UserSetup setup, AccentPreset accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What\'s your goal?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            children: _goals.map((g) {
              final selected = setup.goal == g['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => ref.read(settingsProvider.notifier).setGoal(g['id']!),
                  child: GlassCard(
                    glow: selected,
                    glowColor: accent.glow,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: selected ? accent.dim : const Color.fromRGBO(255, 255, 255, 0.06),
                            ),
                            alignment: Alignment.center,
                            child: Text(g['icon']!, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g['label']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: selected ? accent.primary : Colors.white)),
                                const SizedBox(height: 2),
                                Text('${g['desc']} \u00B7 ${g['time']}', style: const TextStyle(fontSize: 12, color: PaceColors.textSecondary)),
                              ],
                            ),
                          ),
                          _radioCircle(selected, accent),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        PaceButton(
          label: 'Continue \u2192',
          enabled: setup.goal != null,
          onPressed: () => setState(() => _step = 1),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLevelStep(UserSetup setup, AccentPreset accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your experience level', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 6),
        const Text('This helps calibrate weekly mileage and intensity.', style: TextStyle(fontSize: 13, color: PaceColors.textSecondary)),
        const SizedBox(height: 18),
        ..._levels.map((l) {
          final selected = setup.level == l['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => ref.read(settingsProvider.notifier).setLevel(l['id']!),
              child: GlassCard(
                glow: selected,
                glowColor: accent.glow,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l['label']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: selected ? accent.primary : Colors.white)),
                            const SizedBox(height: 3),
                            Text(l['desc']!, style: const TextStyle(fontSize: 12, color: PaceColors.textSecondary)),
                          ],
                        ),
                      ),
                      _radioCircle(selected, accent),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _step = 0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PaceRadii.button),
                    color: const Color.fromRGBO(255, 255, 255, 0.07),
                    border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.12)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('\u2190 Back', style: TextStyle(color: PaceColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PaceButton(
                label: 'Generate Plan',
                enabled: setup.level != null,
                onPressed: () => context.go('/plan'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _radioCircle(bool selected, AccentPreset accent) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? accent.primary : const Color.fromRGBO(255, 255, 255, 0.2),
          width: 1.5,
        ),
        color: selected ? accent.primary : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: Color(0xFF0A0A0C))
          : null,
    );
  }
}
```

- [ ] **Step 3: Update router.dart with setup route**

```dart
// lib/router.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/goal_setup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const GoalSetupScreen(),
      ),
    ],
  );
});
```

- [ ] **Step 4: Verify build**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter analyze
```
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/screens/goal_setup_screen.dart vo2_ai/lib/providers/settings_provider.dart vo2_ai/lib/router.dart
git commit -m "feat: add goal setup wizard with goal and level selection"
```

---

### Task 9: Plan Provider & Plan Screen

**Files:**
- Create: `vo2_ai/lib/providers/plan_provider.dart`
- Create: `vo2_ai/lib/screens/plan_screen.dart`
- Create: `vo2_ai/test/providers/plan_provider_test.dart`
- Modify: `vo2_ai/lib/router.dart`

- [ ] **Step 1: Write plan provider test**

```dart
// test/providers/plan_provider_test.dart

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vo2_ai/data/database.dart';
import 'package:vo2_ai/models/plan_day.dart';
import 'package:vo2_ai/providers/plan_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => await db.close());

  test('savePlanToDb stores all days', () async {
    final userId = await db.into(db.userProfiles).insert(
      UserProfilesCompanion.insert(name: 'Test', goal: 'sub20', level: 'intermediate', daysPerWeek: 5),
    );

    final days = [
      PlanDayModel(week: 1, dayOfWeek: 0, sessionType: 'easy', label: 'Easy Run', distanceKm: 5.0, targetPace: '6:00', effortZone: 2),
      PlanDayModel(week: 1, dayOfWeek: 2, sessionType: 'tempo', label: 'Tempo', distanceKm: 8.0, targetPace: '4:55', effortZone: 4),
    ];

    final planId = await savePlanToDb(db, userId: userId, goal: 'sub20', level: 'intermediate', totalWeeks: 8, days: days);

    final stored = await (db.select(db.planDays)..where((t) => t.planId.equals(planId))).get();
    expect(stored.length, 2);
    expect(stored[0].label, 'Easy Run');
    expect(stored[1].sessionType, 'tempo');
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/providers/plan_provider_test.dart -v
```
Expected: FAIL

- [ ] **Step 3: Implement plan_provider.dart**

```dart
// lib/providers/plan_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../models/plan_day.dart';
import '../services/openrouter_service.dart';
import '../services/plan_generator_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

enum PlanState { idle, generating, ready, error }

class PlanStatus {
  final PlanState state;
  final String? errorMessage;
  final int? planId;
  final List<PlanDay>? days;

  const PlanStatus({this.state = PlanState.idle, this.errorMessage, this.planId, this.days});
}

Future<int> savePlanToDb(
  AppDatabase db, {
  required int userId,
  required String goal,
  required String level,
  required int totalWeeks,
  required List<PlanDayModel> days,
}) async {
  final planId = await db.into(db.trainingPlans).insert(
    TrainingPlansCompanion.insert(
      userId: userId,
      goal: goal,
      level: level,
      totalWeeks: totalWeeks,
      currentWeek: 1,
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
      ),
    );
  }
  return planId;
}

class PlanNotifier extends StateNotifier<PlanStatus> {
  final AppDatabase _db;
  final OpenRouterService? _ai;
  final UserSetup _setup;

  PlanNotifier(this._db, this._ai, this._setup) : super(const PlanStatus());

  Future<void> generatePlan() async {
    if (_ai == null || !_setup.isComplete) return;

    state = const PlanStatus(state: PlanState.generating);

    try {
      final systemPrompt = PlanGeneratorService.buildSystemPrompt(
        goal: _setup.goal!,
        level: _setup.level!,
        daysPerWeek: _setup.daysPerWeek,
      );

      final response = await _ai!.sendMessage(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': 'Generate my training plan now.'},
        ],
        model: 'anthropic/claude-sonnet-4',
      );

      final days = PlanGeneratorService.parsePlanJson(response);
      final totalWeeks = PlanGeneratorService.weeksForGoal(_setup.goal!);

      // Save to DB (userId=1 for MVP single user)
      final planId = await savePlanToDb(
        _db,
        userId: 1,
        goal: _setup.goal!,
        level: _setup.level!,
        totalWeeks: totalWeeks,
        days: days,
      );

      final storedDays = await (
        _db.select(_db.planDays)..where((t) => t.planId.equals(planId))
        ..orderBy([(t) => OrderingTerm.asc(t.week), (t) => OrderingTerm.asc(t.dayOfWeek)])
      ).get();

      state = PlanStatus(state: PlanState.ready, planId: planId, days: storedDays);
    } catch (e) {
      state = PlanStatus(state: PlanState.error, errorMessage: e.toString());
    }
  }

  Future<void> loadExistingPlan() async {
    final plans = await (
      _db.select(_db.trainingPlans)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])..limit(1)
    ).get();

    if (plans.isEmpty) return;

    final plan = plans.first;
    final days = await (
      _db.select(_db.planDays)..where((t) => t.planId.equals(plan.id))
      ..orderBy([(t) => OrderingTerm.asc(t.week), (t) => OrderingTerm.asc(t.dayOfWeek)])
    ).get();

    state = PlanStatus(state: PlanState.ready, planId: plan.id, days: days);
  }
}

final planProvider = StateNotifierProvider<PlanNotifier, PlanStatus>((ref) {
  final db = ref.watch(databaseProvider);
  final authState = ref.watch(authProvider);
  final auth = ref.read(authProvider.notifier);
  final setup = ref.watch(settingsProvider);
  return PlanNotifier(db, auth.service, setup);
});
```

- [ ] **Step 4: Run test**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/providers/plan_provider_test.dart -v
```
Expected: PASS

- [ ] **Step 5: Implement plan_screen.dart**

```dart
// lib/screens/plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../data/database.dart';
import '../providers/plan_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/accent_pill.dart';
import '../widgets/loading_orbit.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  @override
  void initState() {
    super.initState();
    final plan = ref.read(planProvider);
    if (plan.state == PlanState.idle) {
      Future.microtask(() => ref.read(planProvider.notifier).generatePlan());
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProvider);
    final accent = AccentPreset.volt;

    return Scaffold(
      body: SafeArea(
        child: switch (plan.state) {
          PlanState.idle || PlanState.generating => _buildLoading(accent),
          PlanState.ready => _buildPlan(plan.days!, accent),
          PlanState.error => _buildError(plan.errorMessage ?? 'Unknown error'),
        },
      ),
    );
  }

  Widget _buildLoading(AccentPreset accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingOrbit(color: accent.primary),
          const SizedBox(height: 32),
          const Text(
            'Building your plan...',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Personalizing intensities',
            style: TextStyle(fontSize: 13, color: PaceColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPlan(List<PlanDay> days, AccentPreset accent) {
    // Group by week
    final weeks = <int, List<PlanDay>>{};
    for (final day in days) {
      weeks.putIfAbsent(day.week, () => []).add(day);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR PLAN', style: TextStyle(fontSize: 13, color: PaceColors.textSecondary, letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text('Training Schedule', style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
          ),
        ),
        ...weeks.entries.map((entry) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4),
                  child: Text('WEEK ${entry.key}', style: const TextStyle(fontSize: 11, color: PaceColors.textTertiary, letterSpacing: 0.8)),
                ),
                ...entry.value.map((day) => _buildDayCard(day, accent)),
              ],
            ),
          ),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildDayCard(PlanDay day, AccentPreset accent) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final typeColor = switch (day.sessionType) {
      'easy' => PaceColors.easy,
      'tempo' => PaceColors.tempo,
      'long' => PaceColors.long,
      'rest' => PaceColors.rest,
      'interval' => PaceColors.interval,
      _ => Colors.white,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: typeColor.withValues(alpha: 0.15),
                ),
                alignment: Alignment.center,
                child: Text(
                  dayNames[day.dayOfWeek],
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: typeColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(
                      day.sessionType == 'rest'
                          ? 'Rest day'
                          : '${day.distanceKm} km \u00B7 ${day.targetPace}/km \u00B7 Zone ${day.effortZone}',
                      style: const TextStyle(fontSize: 12, color: PaceColors.textSecondary),
                    ),
                  ],
                ),
              ),
              AccentPill(label: day.sessionType.toUpperCase(), color: typeColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Something went wrong', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 13, color: PaceColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => ref.read(planProvider.notifier).generatePlan(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Update router with plan route and shell for tabs**

```dart
// lib/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/goal_setup_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/chat_screen.dart';
import 'core/constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const GoalSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/plan',
            builder: (context, state) => const PlanScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08))),
        ),
        child: BottomNavigationBar(
          backgroundColor: PaceColors.background,
          selectedItemColor: AccentPreset.volt.primary,
          unselectedItemColor: PaceColors.textMuted,
          currentIndex: location == '/chat' ? 1 : 0,
          onTap: (i) => context.go(i == 0 ? '/plan' : '/chat'),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Plan'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Verify build**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter analyze
```
Expected: No issues (chat_screen.dart doesn't exist yet — create a placeholder)

- [ ] **Step 8: Create placeholder chat_screen.dart**

```dart
// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import '../core/constants.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Chat', style: TextStyle(color: PaceColors.textPrimary, fontSize: 17)),
      ),
    );
  }
}
```

- [ ] **Step 9: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/providers/plan_provider.dart vo2_ai/lib/screens/plan_screen.dart vo2_ai/lib/screens/chat_screen.dart vo2_ai/lib/router.dart vo2_ai/test/providers/plan_provider_test.dart
git commit -m "feat: add plan generation, plan screen, and tab navigation"
```

---

### Task 10: Chat Screen

**Files:**
- Create: `vo2_ai/lib/providers/chat_provider.dart`
- Modify: `vo2_ai/lib/screens/chat_screen.dart`
- Create: `vo2_ai/test/providers/chat_provider_test.dart`

- [ ] **Step 1: Write chat provider test**

```dart
// test/providers/chat_provider_test.dart

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vo2_ai/data/database.dart';
import 'package:vo2_ai/providers/chat_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => await db.close());

  test('saveMessage persists to database', () async {
    await saveMessage(db, role: 'user', content: 'Hello');
    await saveMessage(db, role: 'assistant', content: 'Hi!');

    final msgs = await (db.select(db.chatMessages)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();
    expect(msgs.length, 2);
    expect(msgs[0].content, 'Hello');
    expect(msgs[1].content, 'Hi!');
  });

  test('loadHistory returns messages in order', () async {
    await saveMessage(db, role: 'user', content: 'First');
    await saveMessage(db, role: 'assistant', content: 'Second');

    final history = await loadHistory(db);
    expect(history.length, 2);
    expect(history[0]['content'], 'First');
    expect(history[1]['role'], 'assistant');
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/providers/chat_provider_test.dart -v
```
Expected: FAIL

- [ ] **Step 3: Implement chat_provider.dart**

```dart
// lib/providers/chat_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../services/chat_service.dart';
import '../services/openrouter_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'settings_provider.dart';
import 'plan_provider.dart';

Future<void> saveMessage(AppDatabase db, {required String role, required String content}) async {
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

  const ChatMessage({required this.role, required this.content, this.isLoading = false});
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final AppDatabase _db;
  final OpenRouterService? _ai;
  final UserSetup _setup;

  ChatNotifier(this._db, this._ai, this._setup) : super([]);

  Future<void> loadMessages() async {
    final history = await loadHistory(_db);
    state = history.map((m) => ChatMessage(role: m['role']!, content: m['content']!)).toList();
  }

  Future<void> sendMessage(String content) async {
    if (_ai == null) return;

    // Add user message
    state = [...state, ChatMessage(role: 'user', content: content)];
    await saveMessage(_db, role: 'user', content: content);

    // Show loading
    state = [...state, const ChatMessage(role: 'assistant', content: '', isLoading: true)];

    try {
      final context = ChatService.buildContext(
        goal: _setup.goal ?? 'sub20',
        level: _setup.level ?? 'intermediate',
        currentWeek: 1,
        totalWeeks: 8,
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

      final response = await _ai!.sendMessage(
        messages: messages,
        model: 'anthropic/claude-sonnet-4',
      );

      await saveMessage(_db, role: 'assistant', content: response);

      // Replace loading with actual response
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(role: 'assistant', content: response),
      ];
    } catch (e) {
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage(role: 'assistant', content: 'Sorry, I encountered an error. Please try again.'),
      ];
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final db = ref.watch(databaseProvider);
  final auth = ref.read(authProvider.notifier);
  final setup = ref.watch(settingsProvider);
  return ChatNotifier(db, auth.service, setup);
});
```

- [ ] **Step 4: Run tests**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test test/providers/chat_provider_test.dart -v
```
Expected: All 2 tests pass

- [ ] **Step 5: Implement full chat_screen.dart**

```dart
// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../providers/chat_provider.dart';
import '../widgets/glass_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).loadMessages());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final accent = AccentPreset.volt;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI COACH', style: TextStyle(fontSize: 13, color: PaceColors.textSecondary, letterSpacing: 0.3)),
                    const SizedBox(height: 4),
                    Text('Chat', style: Theme.of(context).textTheme.headlineLarge),
                  ],
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(accent)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _buildMessage(messages[i], accent),
                  ),
          ),
          // Input
          _buildInput(accent),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AccentPreset accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: accent.dim),
          const SizedBox(height: 16),
          const Text('Ask your AI coach anything', style: TextStyle(fontSize: 15, color: PaceColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('Training advice, recovery tips, pace guidance...', style: TextStyle(fontSize: 13, color: PaceColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg, AccentPreset accent) {
    final isUser = msg.role == 'user';

    if (msg.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => _dot(i)),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) const SizedBox(width: 0),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? accent.dim : const Color.fromRGBO(255, 255, 255, 0.05),
                borderRadius: BorderRadius.circular(18),
                border: isUser
                    ? Border.all(color: accent.primary.withValues(alpha: 0.3), width: 0.5)
                    : null,
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isUser ? Colors.white : const Color.fromRGBO(255, 255, 255, 0.85),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 0),
        ],
      ),
    );
  }

  Widget _dot(int i) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6, height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PaceColors.textMuted,
      ),
    );
  }

  Widget _buildInput(AccentPreset accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.1)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Ask your coach...',
                  hintStyle: TextStyle(color: PaceColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.primary,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF0A0A0C), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Verify build**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter analyze
```
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/providers/chat_provider.dart vo2_ai/lib/screens/chat_screen.dart vo2_ai/test/providers/chat_provider_test.dart
git commit -m "feat: add AI chat with message persistence and streaming UI"
```

---

### Task 11: Settings Screen

**Files:**
- Create: `vo2_ai/lib/screens/settings_screen.dart`
- Modify: `vo2_ai/lib/router.dart`

- [ ] **Step 1: Implement settings_screen.dart**

```dart
// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(settingsProvider);
    final accent = AccentPreset.volt;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back_ios_rounded, color: PaceColors.textSecondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
            const SizedBox(height: 32),

            // Profile section
            const Text('PROFILE', style: TextStyle(fontSize: 11, color: PaceColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Goal', _goalLabel(setup.goal)),
                    const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 24),
                    _row('Level', setup.level ?? '—'),
                    const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 24),
                    _row('Days/week', '${setup.daysPerWeek}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Accent color
            const Text('APPEARANCE', style: TextStyle(fontSize: 11, color: PaceColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(child: Text('Accent Color', style: TextStyle(color: Colors.white, fontSize: 15))),
                    _colorDot(AccentPreset.volt.primary, setup.accentColor == 'volt', () => ref.read(settingsProvider.notifier).setAccentColor('volt')),
                    const SizedBox(width: 12),
                    _colorDot(AccentPreset.violet.primary, setup.accentColor == 'violet', () => ref.read(settingsProvider.notifier).setAccentColor('violet')),
                    const SizedBox(width: 12),
                    _colorDot(AccentPreset.cyan.primary, setup.accentColor == 'cyan', () => ref.read(settingsProvider.notifier).setAccentColor('cyan')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // API section
            const Text('AI CONNECTION', style: TextStyle(fontSize: 11, color: PaceColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Provider', 'OpenRouter'),
                    const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 24),
                    GestureDetector(
                      onTap: () {
                        ref.read(authProvider.notifier).clearKey();
                        context.go('/auth');
                      },
                      child: Row(
                        children: [
                          const Text('Disconnect', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 15)),
                          const Spacer(),
                          const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        const Spacer(),
        Text(value, style: const TextStyle(color: PaceColors.textSecondary, fontSize: 15)),
      ],
    );
  }

  Widget _colorDot(Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: selected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)] : null,
        ),
      ),
    );
  }

  String _goalLabel(String? goal) {
    return switch (goal) {
      'sub20' => 'Sub-20 5K',
      'hm' => 'Half Marathon',
      'fm' => 'Full Marathon',
      'speed' => 'Speed Builder',
      _ => '—',
    };
  }
}
```

- [ ] **Step 2: Add settings route to router.dart**

Add inside the ShellRoute's routes list:
```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsScreen(),
),
```

- [ ] **Step 3: Verify build**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter analyze
```
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
cd /Users/aju/git/RunApp
git add vo2_ai/lib/screens/settings_screen.dart vo2_ai/lib/router.dart
git commit -m "feat: add settings screen with profile, accent color, and API management"
```

---

### Task 12: End-to-End Smoke Test

**Files:**
- No new files

- [ ] **Step 1: Run all tests**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter test -v
```
Expected: All tests pass

- [ ] **Step 2: Run flutter analyze**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter analyze
```
Expected: No issues found

- [ ] **Step 3: Build for iOS (debug)**

Run:
```bash
cd /Users/aju/git/RunApp/vo2_ai
flutter build ios --debug --no-codesign
```
Expected: Build succeeds

- [ ] **Step 4: Final commit**

```bash
cd /Users/aju/git/RunApp
git add -A
git commit -m "chore: finalize MVP — all tests pass, builds clean"
```
