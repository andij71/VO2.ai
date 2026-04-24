# vo2 ai — Design Spec

## Overview

**vo2 ai** (pace.ai) is a mobile AI running coach that generates personalized training plans and provides freeform coaching via chat. Built with Flutter for iOS + Android, using OpenRouter for LLM access. No backend — everything runs on-device.

## Core Decisions

- **Platform**: Flutter (iOS + Android from one codebase)
- **Data storage**: Local SQLite (via Drift), no cloud backend for MVP
- **AI provider**: OpenRouter — OAuth preferred, API key paste as fallback
- **Visual design**: Port RunApp.html prototype 1:1 (dark glass aesthetic)
- **MVP scope**: AI plan generation + chat only
- **Future phases**: Cloud sync, Garmin integration, health dashboard

## Architecture

```
┌─────────────────────────────────────────────┐
│              vo2 ai (Flutter)               │
├─────────────────────────────────────────────┤
│  UI Layer (Screens)                         │
│  ┌─────────┐ ┌──────────┐ ┌─────────────┐  │
│  │Onboarding│ │Plan View │ │  AI Chat    │  │
│  └─────────┘ └──────────┘ └─────────────┘  │
├─────────────────────────────────────────────┤
│  State Management (Riverpod)                │
├─────────────────────────────────────────────┤
│  Services                                   │
│  ┌──────────────┐  ┌────────────────────┐   │
│  │ Plan Service  │  │ OpenRouter Service │   │
│  └──────────────┘  └────────────────────┘   │
├─────────────────────────────────────────────┤
│  Data Layer                                 │
│  ┌──────────┐  ┌────────────────────────┐   │
│  │  SQLite   │  │  Secure Storage (key) │   │
│  └──────────┘  └────────────────────────┘   │
└─────────────────────────────────────────────┘
         │
         │ HTTPS (direct from device)
         ▼
┌─────────────────────┐
│    OpenRouter API    │
└─────────────────────┘
```

**Key packages:**
- `flutter_riverpod` — state management
- `drift` + `sqlite3_flutter_libs` — local DB
- `flutter_secure_storage` — API key storage
- `dio` — HTTP client for OpenRouter
- `url_launcher` — OAuth redirect
- `go_router` — navigation

## Screens & Navigation

**Flow:** Splash → OpenRouter Auth → Goal Setup → Main (bottom tabs)

**Screens:**
1. **Splash / Welcome** — branding, "Get Started"
2. **OpenRouter Auth** — OAuth flow or manual key input, validates connection
3. **Goal Setup** — pick goal (Sub-20 5K, Half Marathon, Full Marathon, Speed Builder) + level (Beginner/Intermediate/Advanced). One-time wizard, editable in settings.
4. **Plan Generation** — loading animation while AI generates plan
5. **Plan View (home tab)** — weekly calendar, day sessions with type/distance/pace/zone. Tap for details. Current day highlighted.
6. **Chat tab** — freeform AI coach, context-aware (knows plan, current week)
7. **Settings** — goal, API key, accent color, clear data

**Navigation:** 2-tab bottom bar (Plan, Chat) + settings via profile icon.

## Visual Design

Ported directly from RunApp.html prototype:

- **Dark theme** — background `#080809`, frosted glass cards
- **Glass cards** — `rgba(255,255,255,0.055)` background, backdrop blur (20px), border `rgba(255,255,255,0.12)`, r:24, top shine highlight
- **Accent color system** — volt green `#C8FF00` (default), violet `#BF5FFF`, cyan `#00E5FF`
- **Typography** — system font, bold 700 headings, muted secondary `rgba(255,255,255,0.45)`
- **Animations** — fadeInUp, slideInRight transitions, shimmer loading, pulse-glow on active
- **Pills/badges** — session types color-coded (Easy=`#6BF0A0`, Tempo=`#FF8C42`, Long=`#BF5FFF`, Rest=dim)
- **Charts** — sparklines for trends, ring charts for progress
- **Buttons** — full-width, r:16, accent fill with glow shadow, scale on press

**Reusable widget library:** `GlassCard`, `AccentPill`, `SparkLine`, `RingChart`, `LoadingAnimation`

## AI Integration

### Authentication
1. Attempt OAuth with OpenRouter (redirect flow)
2. Fallback: manual API key paste in settings
3. Key stored via `flutter_secure_storage`, never leaves device

### Structured Plan Generation
- System prompt instructs model to return JSON
- Schema: weekly plan with day, session_type, distance, pace, effort_zone, notes
- Inputs: goal, level, available days/week, current fitness context
- Model choice: capable model via OpenRouter (Claude Sonnet, GPT-4o, etc.)
- Response parsed → stored in SQLite → displayed in Plan View

### Freeform Chat
- Conversational AI coach with injected context:
  - Current training plan summary
  - Current week/day position
  - User's goal and level
- Chat history persisted in SQLite
- Streaming responses for real-time feel

### Prompt Architecture
- `system_prompt`: coach personality (knowledgeable, encouraging, concise)
- `context` block: injected per message with current plan state
- User can regenerate plan at any time

## Data Model

```sql
users
  - id (int, PK)
  - name (text)
  - goal (text: sub20/hm/fm/speed)
  - level (text: beginner/intermediate/advanced)
  - days_per_week (int, default 5)
  - created_at (datetime)

training_plans
  - id (int, PK)
  - user_id (int, FK)
  - goal (text)
  - level (text)
  - total_weeks (int)
  - current_week (int)
  - created_at (datetime)

plan_days
  - id (int, PK)
  - plan_id (int, FK)
  - week (int)
  - day_of_week (int, 0=Mon)
  - session_type (text: easy/tempo/long/rest/interval)
  - label (text, e.g. "Threshold Intervals")
  - distance_km (real)
  - target_pace (text, e.g. "4:55")
  - effort_zone (int, 1-5)
  - notes (text, nullable)
  - completed (bool)

chat_messages
  - id (int, PK)
  - role (text: user/assistant/system)
  - content (text)
  - created_at (datetime)

settings
  - key (text, PK)
  - value (text)
```

## Project Structure

```
lib/
  main.dart
  app.dart                    # MaterialApp, theme, routing

  core/
    theme.dart                # Dark theme, accent colors, glass styles
    constants.dart            # Design tokens from HTML prototype

  data/
    database.dart             # Drift database definition
    tables/                   # Table definitions
    daos/                     # Data access objects

  services/
    openrouter_service.dart   # API calls, auth, streaming
    plan_generator.dart       # Prompt building, JSON parsing
    chat_service.dart         # Context injection, message handling

  providers/
    plan_provider.dart
    chat_provider.dart
    auth_provider.dart
    settings_provider.dart

  widgets/
    glass_card.dart
    accent_pill.dart
    spark_line.dart
    ring_chart.dart
    loading_animation.dart

  screens/
    welcome_screen.dart
    auth_screen.dart
    goal_setup_screen.dart
    plan_screen.dart
    chat_screen.dart
    settings_screen.dart
```

## Future Phases (Post-MVP)

1. **Cloud sync** — optional backend for multi-device sync
2. **Garmin integration** — pull HR, pace, distance, sleep, HRV from Garmin Connect API
3. **Health dashboard** — HRV, sleep, readiness, resting HR widgets (as in prototype)
4. **Workout completion** — mark sessions done, AI adjusts plan based on actual performance
5. **Notifications** — daily session reminders, recovery suggestions
