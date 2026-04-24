// test/providers/chat_provider_test.dart

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/database.dart';
import 'package:app/providers/chat_provider.dart';

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
