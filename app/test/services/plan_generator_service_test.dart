// test/services/plan_generator_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/plan_generator_service.dart';

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
