// test/services/chat_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/chat_service.dart';

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
