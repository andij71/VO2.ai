// lib/core/disclaimer_text.dart
//
// Medical / safety disclaimer shown on first launch before the user can
// use AI-generated training plans. Kept as plain constants so the same text
// can be reused inside the EULA screen or Settings.

class DisclaimerText {
  DisclaimerText._();

  // -----------------------------------------------------------------
  // ENGLISH
  // -----------------------------------------------------------------
  static const titleEn = 'Before you start';

  static const bodyEn = '''
VO2.ai generates personalized running plans using AI. It is designed for general fitness and training purposes and is **not a medical device**.

- The AI does not know your medical history. Training plans are suggestions based on the goal and level you enter, not personalized medical advice.
- Running puts stress on your heart, joints, and muscles. If you have any cardiovascular condition, are recovering from an injury or surgery, are pregnant, or have not exercised in a long time, talk to a qualified physician before following any plan in this app.
- Listen to your body. Stop running and seek medical help immediately if you experience chest pain, dizziness, shortness of breath beyond normal exertion, or sharp persistent pain.
- You are responsible for your own safety, warm-up, route choice, hydration, and environmental conditions.
- This app does not replace a coach, a doctor, or a physiotherapist.

By continuing you confirm that you have read and understood this notice and that you train at your own risk.
''';

  static const acceptLabelEn = 'I understand and accept';
  static const continueLabelEn = 'Continue';

  // -----------------------------------------------------------------
  // GERMAN
  // -----------------------------------------------------------------
  static const titleDe = 'Bevor du startest';

  static const bodyDe = '''
VO2.ai erstellt personalisierte Laufpläne mithilfe von KI. Die App ist für allgemeine Fitness- und Trainingszwecke gedacht und **kein Medizinprodukt**.

- Die KI kennt deine medizinische Vorgeschichte nicht. Trainingspläne sind Vorschläge auf Basis des eingegebenen Ziels und Leistungsstands — keine individuelle medizinische Beratung.
- Laufen belastet Herz, Gelenke und Muskulatur. Wenn du an einer Herz-Kreislauf-Erkrankung leidest, dich von einer Verletzung oder Operation erholst, schwanger bist oder länger nicht trainiert hast, sprich bitte mit einer qualifizierten Ärztin oder einem Arzt, bevor du nach einem Plan in dieser App trainierst.
- Höre auf deinen Körper. Brich das Training ab und suche sofort ärztliche Hilfe, wenn du Brustschmerzen, Schwindel, ungewöhnliche Atemnot oder anhaltende scharfe Schmerzen spürst.
- Du bist selbst verantwortlich für Sicherheit, Aufwärmen, Streckenwahl, Flüssigkeitszufuhr und äußere Bedingungen.
- Diese App ersetzt weder Trainer:in noch Ärztin/Arzt noch Physiotherapie.

Mit „Ich habe verstanden und stimme zu" bestätigst du, dass du diesen Hinweis gelesen und verstanden hast und auf eigenes Risiko trainierst.
''';

  static const acceptLabelDe = 'Ich habe verstanden und stimme zu';
  static const continueLabelDe = 'Weiter';

  // -----------------------------------------------------------------
  // LOCALE HELPER
  // -----------------------------------------------------------------
  static String title(String languageCode) =>
      languageCode.startsWith('de') ? titleDe : titleEn;

  static String body(String languageCode) =>
      languageCode.startsWith('de') ? bodyDe : bodyEn;

  static String acceptLabel(String languageCode) =>
      languageCode.startsWith('de') ? acceptLabelDe : acceptLabelEn;

  static String continueLabel(String languageCode) =>
      languageCode.startsWith('de') ? continueLabelDe : continueLabelEn;
}
