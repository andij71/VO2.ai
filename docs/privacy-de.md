---
title: Datenschutzerklärung
layout: default
permalink: /privacy-de/
---

# Datenschutzerklärung — VO2.ai

*Stand: 23. April 2026*

**Diese Seite ist auch auf [English](./privacy) verfügbar.**

VO2.ai ist eine quelloffene iOS-Anwendung, die als persönliches, nicht-kommerzielles Open-Source-Projekt entwickelt wird. Diese Datenschutzerklärung erklärt, welche Daten in der App verarbeitet werden, wo sie verarbeitet werden und welche Rechte du hast.

## 1. Verantwortlicher

Bei Fragen zum Datenschutz rund um diese App kannst du dich wenden an:

> **Andreas Junemann**
> E-Mail: `andreasjunemann2@gmail.com`
> Projekt: https://github.com/andij71/VO2.ai

## 2. Zusammenfassung in einfacher Sprache

- **Wir betreiben keinen Server.** Es gibt keinen VO2.ai-Backend-Server. Alle deine Daten bleiben auf deinem Gerät, gehen direkt zu Strava (wenn du es verbindest) oder werden von deinem Gerät direkt an OpenRouter gesendet (dem LLM-Routing-Dienst, für den du deinen eigenen API-Key mitbringst).
- **Wir tracken dich nicht.** Keine Analytics, keine Werbe-IDs, keine Dritt-Tracker.
- **Wir sammeln selbst keine personenbezogenen Daten.** Wir sehen niemals deine Läufe, deine Chats, deine Trainingspläne oder deine API-Keys.
- **Du kannst alles jederzeit löschen**, direkt in der App (Einstellungen → *Konto und Daten löschen*).

## 3. Welche Daten werden verarbeitet und wo

### 3.1 Lokal auf deinem Gerät gespeicherte Daten

Folgende Daten werden ausschließlich auf deinem iPhone gespeichert und niemals an uns übertragen:

- Dein Trainingsziel, Leistungsstand und deine Präferenzen.
- Dein generierter Trainingsplan und die einzelnen Einheiten.
- Dein Chatverlauf mit dem KI-Coach.
- Zwischengespeicherte Strava-Aktivitäten (falls Strava verbunden ist).
- Deine Modell- und Farbeinstellungen.

Speicherort: SQLite-Datenbank im abgeschotteten App-Container (via Drift) sowie iOS-`UserDefaults` (via `shared_preferences`). Diese Daten werden nur dann in ein iCloud-Backup aufgenommen, wenn du iCloud-Backups für die App aktiviert hast.

### 3.2 Im iOS-Schlüsselbund gespeicherte Daten

- Dein OpenRouter-API-Schlüssel.
- Deine Strava-OAuth-Access- und Refresh-Tokens.

Speicherort: iOS Keychain via `flutter_secure_storage`. Keychain-Einträge sind durch Gerätecode/Biometrie geschützt und werden üblicherweise nicht in unverschlüsselte Backups übernommen.

### 3.3 An OpenRouter gesendete Daten

Bei Nutzung des KI-Coach-Chats oder beim Generieren eines Trainingsplans werden folgende Daten von deinem Gerät direkt an OpenRouter (`https://openrouter.ai`) unter deinem eigenen API-Schlüssel gesendet:

- Dein Ziel, Leistungsstand, bevorzugte Lauftage und aktuelles Wochenvolumen.
- Zusammenfassungen deiner letzten Strava-Läufe (falls verbunden), z. B. Distanz, Pace, Dauer.
- Die von dir geschriebenen Chatnachrichten.
- Das gewählte KI-Modell (z. B. `google/gemini-2.5-flash-lite`).

OpenRouter wird von OpenRouter Inc. betrieben. Dein Verhältnis zu OpenRouter unterliegt deren eigenen Nutzungsbedingungen und Datenschutzbestimmungen:
<https://openrouter.ai/privacy>

OpenRouter leitet deine Anfrage an den zugrundeliegenden Modell-Anbieter weiter (z. B. Google, Anthropic, OpenAI), die ebenfalls beschränkt Metadaten gemäß ihrer jeweiligen Richtlinien speichern können. VO2.ai hat auf diese Daten keinen Einfluss und keinen Zugriff, sobald sie dein Gerät verlassen haben.

### 3.4 Mit Strava ausgetauschte Daten (optional)

Wenn du Strava verbindest, nutzt die App den Standard-OAuth-2.0-Flow von Strava. Folgendes geschieht direkt zwischen deinem Gerät und Strava:

- Ein In-App-Browser öffnet `https://www.strava.com/oauth/authorize` für deinen Login.
- Strava gibt einen Authorization-Code über das URL-Schema `vo2ai://redirect` an die App zurück.
- Die App tauscht diesen Code direkt beim Token-Endpoint von Strava gegen ein Access-Token.
- Die App ruft deine letzten Lauf-Aktivitäten (90 Tage, nur Run/TrailRun/VirtualRun) über die Strava-API ab.

Deine Strava-Zugangsdaten kommen dabei zu keinem Zeitpunkt mit VO2.ai in Berührung. Es gilt Stravas eigene Datenschutzerklärung:
<https://www.strava.com/legal/privacy>

Du kannst die Strava-Verbindung jederzeit in den Einstellungen lösen. Dabei wird eine Deautorisierung bei Strava ausgelöst und das lokale Token gelöscht.

### 3.5 Kalender (optional)

Wenn du Kalenderzugriff erlaubst, schreibt die App deine geplanten Laufeinheiten in den von dir gewählten Kalender (via iOS-Framework EventKit). Einträge werden lokal geschrieben und nicht an uns übertragen.

### 3.6 Absturzberichte und Diagnose

VO2.ai enthält kein eigenes Crash-Reporting. Wenn du in iOS unter Einstellungen → Datenschutz → Analyse & Verbesserungen die Option „Mit App-Entwickler:innen teilen" aktiviert hast, kann Apple anonymisierte Absturzberichte über App Store Connect an den Entwickler senden. Hierfür gelten die Datenschutzpraktiken von Apple.

## 4. Rechtsgrundlagen (DSGVO)

Da wir keinen eigenen Server betreiben, verarbeiten wir im klassischen Sinne keine personenbezogenen Daten als Verantwortliche. Für die oben beschriebenen, eng begrenzten Datenflüsse gilt:

- **Lokal gespeicherte Daten (3.1, 3.2):** Verarbeitung auf deinem eigenen Gerät zum Zweck der App-Nutzung. Keine Übertragung an uns.
- **An OpenRouter übertragene Daten (3.3):** Du stellst den API-Key bereit und löst jede Anfrage selbst aus. OpenRouter ist der von dir gewählte Auftragsverarbeiter.
- **An Strava übertragene Daten (3.4):** Du initiierst die Verbindung und willigst im OAuth-Dialog in die Verarbeitung durch Strava ein.
- **Kalendereinträge (3.5):** Erfordern deine ausdrückliche iOS-Berechtigung und eine Aktion in der App.

Soweit einschlägig, erfolgt die Verarbeitung auf Grundlage deiner Einwilligung (Art. 6 Abs. 1 lit. a DSGVO) und zur Erbringung eines von dir angeforderten Dienstes (Art. 6 Abs. 1 lit. b DSGVO).

## 5. Internationale Datenübermittlungen

OpenRouter, Strava und die zugrundeliegenden LLM-Anbieter können Daten in den USA oder anderen Ländern außerhalb der EU/des EWR verarbeiten. Wenn du eine Anfrage an diese Dienste auslöst, bestätigst du, dass deine Anfragedaten international übertragen werden. VO2.ai hat auf diese Übermittlungen keinen Einfluss.

## 6. Speicherdauer

- Lokale Daten bleiben auf deinem Gerät, bis du sie über *Konto und Daten löschen* in den Einstellungen entfernst, die App deinstallierst oder dein iPhone zurücksetzt.
- Die Speicherdauer bei OpenRouter und Strava richtet sich nach deren eigenen Richtlinien.

## 7. Deine Rechte

Da VO2.ai keine deiner personenbezogenen Daten auf eigenen Servern vorhält, beziehen sich die Betroffenenrechte (Auskunft, Berichtigung, Löschung, Datenübertragbarkeit, Widerspruch) vor allem auf die lokal bei dir gespeicherten Daten und die von OpenRouter und Strava verarbeiteten Daten:

- **Auskunft und Datenportabilität:** Deine lokalen Daten gehören dir. Du kannst sie in der App einsehen; der Quellcode ist Open Source.
- **Löschung:** Nutze *Einstellungen → Konto und Daten löschen* in der App.
- **Für Daten bei OpenRouter:** Wende dich direkt an OpenRouter über deren Datenschutzseite.
- **Für Daten bei Strava:** Wende dich direkt an Strava über deren Datenschutzseite.
- **Anliegen gegenüber dem Entwickler:** E-Mail an die Adresse in Abschnitt 1.

Als Nutzer:in mit Wohnsitz in der EU/im EWR hast du zudem das Recht, eine Beschwerde bei deiner zuständigen Datenschutz-Aufsichtsbehörde einzulegen.

## 8. Kinder

VO2.ai richtet sich nicht an Kinder unter 13 Jahren. Die App beinhaltet körperliche Anstrengung und KI-generierte Trainingsempfehlungen, die für kleine Kinder nicht geeignet sind. Mit Nutzung der App bestätigst du, dass du mindestens 16 Jahre alt bist oder die Zustimmung einer erziehungsberechtigten Person hast, sofern das nach örtlichem Recht erforderlich ist.

## 9. Änderungen dieser Datenschutzerklärung

Diese Erklärung kann sich mit der Weiterentwicklung der App ändern. Das Datum oben auf der Seite zeigt die jeweils geltende Fassung an. Wesentliche Änderungen werden in den App-Store-Release-Notes angekündigt.

## 10. Open Source

Der vollständige Quellcode von VO2.ai ist unter einer Open-Source-Lizenz verfügbar. Du kannst jeden API-Aufruf, jedes gespeicherte Datenfeld und jeden Netzwerk-Endpunkt nachvollziehen. Siehe: https://github.com/andij71/VO2.ai

---

*VO2.ai ist ein unabhängiges, nicht-kommerzielles Open-Source-Projekt. Es steht in keinem Zusammenhang mit Strava, OpenRouter, Anthropic, Google, OpenAI oder Apple, wird von diesen nicht unterstützt und ist nicht von ihnen gesponsert.*
