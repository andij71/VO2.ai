# App Store Connect — Exact Settings Walkthrough

Field-by-field guide for configuring VO2.ai in App Store Connect for a
first submission. Values to paste are shown in fenced code blocks.
Placeholders in `<ANGLE_BRACKETS>` must be replaced before submitting.

Open App Store Connect → My Apps → VO2.ai.

---

## 1. App Information (left sidebar → App Information)

### Localizable Information (set the primary localization first, then add others)

**Primary Language:** `English (U.S.)`
*Recommendation: Use English as primary even though you are German.
App Store Review is US-based; English avoids translation friction.
You add German as an additional localization below.*

**Name:**
```
VO2.ai
```

**Subtitle:**
```
Your AI running coach
```

**Privacy Policy URL:**
```
https://andij71.github.io/VO2.ai/privacy/
```

**Subscription Privacy Policy URL:** *leave blank (no subscriptions)*

### After saving English, add German localization (top-right language dropdown → Add)

**Name (German):**
```
VO2.ai
```

**Subtitle (German):**
```
Dein KI-Laufcoach
```

**Privacy Policy URL (German):**
```
https://andij71.github.io/VO2.ai/privacy-de/
```

### General Information

**Bundle ID:** Select the one you registered in Apple Developer Portal.
Usually `ai.vo2.app` or `com.junemann.vo2ai`. Must match
`PRODUCT_BUNDLE_IDENTIFIER` in your Xcode project.

**SKU:** Your own internal ID, never shown to users. Use:
```
vo2ai-ios-1
```

**User Access:** `Full Access` (unless you plan team access later).

**Primary Category:** `Health & Fitness`
**Secondary Category:** `Sports`

*Note on category choice: "Health & Fitness" fits the app better than
"Sports", but triggers slightly stricter review under guideline 1.4.1
(physical harm). Your medical disclaimer is exactly the mitigation Apple
looks for here. Do NOT pick "Medical" — that category requires
additional submissions and locks you into medical-device scrutiny.*

**Content Rights:**
"Does your app contain, display, or access third-party content?" → `Yes`
*(because of Strava integration and OpenRouter)*

"Do you have all necessary rights to use the third-party content in your
app?" → `Yes` *(OAuth for Strava, user-supplied key for OpenRouter —
both legitimate)*

**Age Rating:** Click *Edit* and fill in the questionnaire. Recommended
answers for this app:

| Category | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | **Infrequent/Mild** *(because of training suggestions)* |
| Alcohol, Tobacco, or Drug Use or References | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Contests | None |
| Unrestricted Web Access | **No** *(only Strava OAuth + policy links, controlled)* |
| Gambling and Contests | No |

Final rating should land at **4+** or **9+**. Either is fine.

---

## 2. Pricing and Availability (left sidebar)

**Price Schedule:**
- Price: `USD 0.00 (Free)`
- No price tier, no introductory pricing.

**Availability:**
- Countries: `All Available Territories` (default is fine for free app).
  *Only restrict if you specifically want to exclude e.g. sanctioned
  countries, which the App Store handles automatically anyway.*

**App Distribution Methods:**
- `Available on the App Store` ✓
- `Pre-Order` ✗

**Volume Purchase:**
- Leave default ("Available")

**Tax Category:**
- `App Store Software` (the default for apps)
- *Note: Because your app is free, the new Global Tax categories matter
  less. Just accept the default.*

---

## 3. App Privacy (left sidebar — this is the "Nutrition Label")

Click **Get Started** if this is your first time filling it out.

### Question 1: "Do you or your third-party partners collect data from this app?"

Answer: **No, we do not collect data from this app.**

*Justification (keep this in mind if review asks): VO2.ai operates no
server and includes no analytics, advertising, or tracking SDKs. User
inputs to OpenRouter are sent directly from the device under the user's
own API key — Apple's own documentation (App Privacy Details FAQ)
treats user-initiated transfers to a third-party service the user is
contracted with as not "collected by the developer". Same logic for
OAuth flows to Strava.*

*If you want to be extra conservative, you can also declare the types
below. This is NOT required but defensible. Risk: making declarations
you do not need can trigger questions from reviewers. Pick ONE path
and stick with it. My recommendation is the simpler "No" path above.*

<details>
<summary>Alternative conservative path (only if you want to over-declare)</summary>

Select **Yes, I collect data from this app**, then:

Data Types:
- **User Content → Other User Content** (for chat prompts, training goals)
  - Linked to user: No
  - Used for tracking: No
  - Purpose: **App Functionality**

That is the only category that could conceivably apply. Do NOT select
"Health & Fitness" unless you process HealthKit data (you do not).

</details>

---

## 4. Prepare for Submission (Version 1.0 page, left sidebar → 1.0)

### Version Information (at the top)

**What's New in This Version:** *(required from v1.0.1 onwards, leave blank for v1.0.0 or use:)*
```
First release of VO2.ai.
```

**App Preview and Screenshots:**
- 6.9" Display (required): upload 3–5 screenshots at **1320 x 2868 px**.
  Use the `scripts/screenshots.sh` helper in the repo.
- 6.5" Display: optional — Apple will auto-downscale 6.9" for older
  devices. Skip to save time on first submission.
- iPad Pro 13": only if your iPad support is polished. Skip on first
  submission (iPhone-only is fine).

### Promotional Text (170 char max, editable without resubmission)

```
Tell VO2.ai your goal. Get a personalized training plan in seconds. Chat with your AI coach. Sync Strava. Your data stays on your device.
```

### Description (4000 char max)

Paste from `docs/app-store-copy.md` → Description (English) section.

### Keywords (100 char max, comma-separated, NO spaces after commas)

```
training,marathon,5k,10k,halfmarathon,pace,coach,runner,vo2max,strava,fitness,workout,cardio
```

### Support URL (required)

```
https://github.com/andij71/VO2.ai/issues
```

### Marketing URL (optional)

```
https://andij71.github.io/VO2.ai/
```

### Version (at the bottom)

**Version Number:** `1.0.0`
**Copyright:** `© 2026 Andreas Junemann`
**Trade Representative Contact Information:** Leave blank unless
distributing in South Korea.

**Routing App Coverage File:** N/A (skip)

### Build (select after TestFlight build has processed)

Click `+ Build` once your build shows up as "Ready to Submit". Select
the exact build number you tested on TestFlight.

**Export Compliance:** This modal appears either here or during build
upload. Answers:
- "Does your app use encryption?" → **Yes**
- "Does your app qualify for any of the exemptions provided in
  Category 5, Part 2 of the U.S. Export Administration Regulations?"
  → **Yes**
- "Does your app implement any proprietary encryption algorithms instead
  of, or in addition to, using or accessing the encryption features
  provided by Apple's operating systems?" → **No**
- "Does your app implement any standard encryption algorithms instead
  of, or in addition to, using or accessing the encryption features
  provided by Apple's operating systems?" → **No**

This places you in the "Exempt" category. Apple auto-generates the
Export Compliance token.

---

## 5. General App Information (inside Version 1.0, scroll down)

### App Review Information

**Sign-in required:** `Yes`

**Sign-in information:**
- **User name:** `demo@vo2.ai` *(placeholder, not actually used)*
- **Password:** `<PASTE_REVIEWER_OPENROUTER_KEY>`

*The app uses an OpenRouter API key as "login". Treat the key as the
password for review purposes. Make this clear in the Notes field below.*

**Contact Information:**
- **First Name:** `Andreas`
- **Last Name:** `Junemann`
- **Phone Number:** `<YOUR_PHONE_INTERNATIONAL_FORMAT>` *(e.g. +49 151 12345678)*
- **Email:** `andreasjunemann2@gmail.com`

**Notes:** Paste the full content of `docs/app-store-review-notes.md`
section "1. Reviewer Notes". Strip the markdown `>` quote markers before
pasting.

**Attachment:** Optional. A 30-second screen recording of the full user
flow (disclaimer → setup → plan → chat → delete) helps immensely but
isn't required.

---

## 6. Version Release (inside Version 1.0, bottom)

### Release Settings

**Version Release:**
- `Manually release this version` ✓
  *Lets you hold the release after approval until you are ready — e.g.
  wait for a weekend or a working GitHub Pages site.*
- Do NOT select "Automatically release this version" on first release.

**Phased Release for Automatic Updates:**
- Enable `Release update over a 7-day period using phased release`
- *This kicks in for subsequent updates (v1.0.1+), not v1.0. Enable now
  so it is set for later.*

### Earlier Release

- Leave unchecked. v1.0 has no earlier release.

---

## 7. TestFlight Setup (left sidebar → TestFlight)

Before submitting for App Review, you MUST have tested via TestFlight.

### Test Information

Fill out the Test Information tab:

**Beta App Description (for testers):**
```
VO2.ai is a free, open-source AI running coach. Please test the full
flow: disclaimer acceptance, API key entry, goal setup, plan generation,
Strava connection (optional), chat, and account deletion. Report bugs
via the feedback button in TestFlight.
```

**Beta App Review Information:** Same as App Review notes above.

**Feedback Email:** `andreasjunemann2@gmail.com`

**Marketing URL:** Same as above.

**Privacy Policy URL:** Same as above.

**License Agreement:** Use Apple's Standard EULA (default).

### Internal Testing Group

- Add yourself as the only internal tester initially.
- Each uploaded build automatically becomes available to internal
  testers without review.

### External Testing (optional, only if you want friends to test)

- Creating an external group triggers a short "Beta App Review" (~24h).
- Fewer hoops: stay internal for v1.0.

---

## 8. The exact submission sequence

1. Upload a release build via Xcode Organizer (Archive → Distribute
   → App Store Connect → Upload).
2. Wait 20–60 minutes for processing.
3. Internal TestFlight: install on your iPhone, run through the full
   flow at least twice. Fix any issues. Repeat upload until clean.
4. Fill out all fields in sections 1–6 above.
5. At the top of the Version 1.0 page click **Add for Review**.
6. Confirm → **Submit to App Review**.
7. Status changes to "Waiting for Review". Typical time to first
   verdict: 24–36h. Can be 5 days.
8. If approved: status becomes "Pending Developer Release". Click
   "Release This Version" when you want to go live.
9. If rejected: read the message in Resolution Center, fix, upload a
   new build (bump build number), resubmit.

---

## 9. Checklist before clicking "Submit to App Review"

- [ ] Bundle ID matches Xcode project
- [ ] Privacy Policy URL opens successfully in a browser (both EN and DE)
- [ ] Support URL opens successfully
- [ ] App Icon 1024x1024 uploaded, no transparency, no rounded corners
- [ ] At least 3 screenshots at 6.9" (1320x2868)
- [ ] Description proof-read, no typos, no Lorem ipsum
- [ ] Keywords string is under 100 chars and no trailing commas
- [ ] Age Rating questionnaire completed
- [ ] App Privacy answered ("No data collected" path)
- [ ] Export Compliance answered (exempt)
- [ ] Reviewer notes pasted with working OpenRouter demo key
- [ ] OpenRouter demo key has at least $5 USD credit
- [ ] You have personally installed the submission build via TestFlight
      and walked through disclaimer → setup → plan → chat → delete
- [ ] `Manually release this version` is selected
- [ ] Version number = `1.0.0`, Build number increments on every upload

---

## 10. After submission — common status transitions

| Status | Meaning |
|---|---|
| `Waiting for Review` | Queued |
| `In Review` | Reviewer has started. Typically takes 1–12h |
| `Pending Developer Release` | Approved. You control when it goes live |
| `Ready for Sale` | Live on the App Store |
| `Rejected` | Read Resolution Center message; fix; resubmit |
| `Metadata Rejected` | Text/screenshot issue only; fix metadata, no new build needed |
| `Developer Rejected` | You pulled the submission (can resubmit) |

---

## 11. If you get a Metadata Rejection (very common, low-stakes)

Metadata rejections do NOT require a new build upload. Fix the text
field Apple flagged, hit "Resubmit to App Review" from the same page.
Second review is usually fast (often within 12h).

Common metadata rejections for AI apps:
- Keywords mentioning competitor apps ("Strava" is OK — integration is
  real — but "ChatGPT", "Claude" are not unless you're the brand).
- Promotional text over-promising ("best", "#1", "most accurate").
- Screenshots with fake data that looks like a different app.
- Privacy Policy URL returning 404.

---

## 12. If you get a 5.1.1 or 5.1.2 Privacy Rejection (the AI-app classic)

Usually a concern that the app silently collects something that wasn't
disclosed. Response template (paste in Resolution Center):

```
Thank you for the review. VO2.ai operates no backend server. All
training plan requests are sent from the device directly to OpenRouter
under the user's own API key, which the user enters manually during
onboarding. No user-supplied content is transmitted to any server we
control. Our Privacy Manifest (PrivacyInfo.xcprivacy) declares zero
data collection and zero tracking. The complete source code is
open source at https://github.com/andij71/VO2.ai — you
can verify every network call.

Please let us know if you need additional documentation.
```

---

## 13. Useful App Store Connect URLs to bookmark

- Dashboard: https://appstoreconnect.apple.com/apps
- Resolution Center: accessible from any app's version page
- Crashes: App Store Connect → your app → App Analytics → Diagnostics
- Sales reports: App Store Connect → Apps → Sales and Trends
