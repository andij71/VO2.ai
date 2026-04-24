---
title: Privacy Policy
layout: default
permalink: /privacy/
---

# Privacy Policy — VO2.ai

*Last updated: April 23, 2026*

**This page is available in [Deutsch](../privacy-de/).**

VO2.ai is an open-source iOS application developed as a personal, non-commercial project. This Privacy Policy explains what data the app handles, where it is processed, and what rights you have.

## 1. Controller

For any privacy-related matter regarding this app, you can contact the developer at:

> **Andreas Junemann**
> Email: `andreasjunemann2@gmail.com`
> Project: https://github.com/andij71/VO2.ai

## 2. Summary in plain language

- **We operate no backend.** There is no VO2.ai server. All your data stays on your device, goes directly to Strava (if you connect it), or is sent directly from your device to OpenRouter (the LLM routing service you bring your own API key for).
- **We do not track you.** No analytics, no advertising IDs, no third-party trackers.
- **We do not collect personal data ourselves.** We never see your runs, your chats, your training plans, or your API keys.
- **You can delete everything any time**, directly in the app (Settings → *Delete Account & Data*).

## 3. What data is processed, and where

### 3.1 Data stored locally on your device

The following data is stored exclusively on your iPhone and never transmitted to us:

- Your training goal, level, and preferences.
- Your generated training plan and daily sessions.
- Your chat conversation with the AI coach.
- Cached Strava activity summaries (if you connected Strava).
- Your selected AI model and accent color preferences.

Storage location: SQLite database inside the app's sandboxed container (via Drift) and iOS `UserDefaults` (via `shared_preferences`). This data is included in your iCloud device backup only if you have iCloud backup enabled for the app.

### 3.2 Data stored in the iOS Keychain

- Your OpenRouter API key.
- Your Strava OAuth access and refresh tokens.

Storage location: iOS Keychain via `flutter_secure_storage`. Keychain data is protected by the device passcode / biometrics and is generally not included in unencrypted backups.

### 3.3 Data sent to OpenRouter

When you use the AI coach chat or generate a training plan, the following data is sent from your device directly to OpenRouter (`https://openrouter.ai`) under your own API key:

- Your goal, level, running day preferences, and current weekly volume.
- Summaries of your recent Strava runs (if connected), such as distance, pace, duration.
- The chat messages you type.
- The AI model you selected (e.g., `google/gemini-2.5-flash-lite`).

OpenRouter is operated by OpenRouter Inc. Your relationship with OpenRouter is governed by their own Terms of Service and Privacy Policy:
<https://openrouter.ai/privacy>

OpenRouter forwards your request to the underlying model provider (e.g., Google, Anthropic, OpenAI), who may also retain limited metadata according to their own policies. VO2.ai has no influence over and no access to this data once it leaves your device.

### 3.4 Data exchanged with Strava (optional)

If you choose to connect Strava, the app uses Strava's standard OAuth 2.0 flow. The following happens directly between your device and Strava:

- An in-app browser is opened on `https://www.strava.com/oauth/authorize` for you to log in.
- Strava returns an authorization code to the app via the `vo2ai://redirect` URL scheme.
- The app exchanges this code for an access token directly with Strava's token endpoint.
- The app fetches your recent running activities (last 90 days, Run/TrailRun/VirtualRun types only) via Strava's API.

Your Strava credentials never touch VO2.ai. Strava's own privacy policy applies:
<https://www.strava.com/legal/privacy>

You can disconnect Strava at any time in Settings. This triggers a deauthorization request to Strava and deletes the local tokens.

### 3.5 Calendar (optional)

If you grant calendar access, the app writes your planned running sessions into the calendar you choose (via the iOS EventKit framework). Events are written locally and are not transmitted to us.

### 3.6 Crash reports and diagnostics

VO2.ai does not include its own crash reporting. If you have enabled "Share With App Developers" in iOS Settings → Privacy → Analytics & Improvements, Apple may send anonymized crash reports to the developer via App Store Connect. This is governed by Apple's privacy practices.

## 4. Legal bases (GDPR / EU users)

Because we operate no backend, we do not process personal data about you as a controller in the traditional sense. For the limited data flows described above:

- **Locally stored data (3.1, 3.2):** processed on your own device for the purpose you use the app for. No transmission to us.
- **Data sent to OpenRouter (3.3):** you are the one who provides the API key and triggers each request. OpenRouter is your chosen processor.
- **Data sent to Strava (3.4):** you initiate the connection and consent to Strava's processing when you authorize the OAuth scope.
- **Calendar writes (3.5):** require your explicit iOS permission and an in-app action.

Where applicable, the legal basis is your consent (Art. 6(1)(a) GDPR) and the performance of a service you requested (Art. 6(1)(b) GDPR).

## 5. International transfers

OpenRouter, Strava, and the underlying LLM providers may process data in the United States or other jurisdictions outside the EU/EEA. When you initiate requests to these services, you acknowledge that your request data is transmitted internationally. VO2.ai does not influence these transfers.

## 6. Data retention

- Local data remains on your device until you delete it via *Delete Account & Data* in Settings, uninstall the app, or manually reset your iPhone.
- OpenRouter's and Strava's retention is governed by their own policies.

## 7. Your rights

Because VO2.ai does not hold any of your personal data on servers we control, data-subject rights (access, rectification, erasure, portability, objection) relate primarily to the data you hold locally and the data processed by OpenRouter and Strava:

- **Access & portability:** your local data is yours. You can view it in the app; source code is open source.
- **Erasure:** use *Settings → Delete Account & Data* inside the app.
- **For data at OpenRouter:** contact OpenRouter directly via their privacy page.
- **For data at Strava:** contact Strava directly via their privacy page.
- **To raise a concern with the developer:** email the address in Section 1.

If you are an EU/EEA resident, you also have the right to lodge a complaint with your local data-protection authority.

## 8. Children

VO2.ai is not directed at children under 13. The app involves physical exercise and AI-generated training advice that is not appropriate for young children. By using the app you confirm that you are at least 16 years old, or have the consent of a parent or legal guardian where required by local law.

## 9. Changes to this Policy

This Privacy Policy can change as the app evolves. The effective date at the top of this page indicates the current version. Substantive changes will be reflected in the app's release notes on the App Store.

## 10. Open Source

The complete source code of VO2.ai is available under an open-source license. You can inspect every API call, every piece of stored data, and every network endpoint used. See: https://github.com/andij71/VO2.ai

---

*VO2.ai is an independent, non-commercial open-source project. It is not affiliated with, endorsed by, or sponsored by Strava, OpenRouter, Anthropic, Google, OpenAI, or Apple.*
