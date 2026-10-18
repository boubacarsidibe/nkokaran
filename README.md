# N'Ko Kalan

A Flutter app for learning to read and write N'Ko (ߒߞߏ) — the Manding-language
alphabet — built as a Duolingo-style gamified learning loop.

## Features

**Learning path**
- 7 units: vowels, four consonant groups, digits, and a "first word" capstone
- Seven exercise types across lessons: multiple-choice (character↔sound), a
  match-the-pairs checkpoint, a tile-tap word-bank exercise, listening
  (identify a letter by its sound), pronunciation (listen to the Djelia voice and repeat aloud), handwriting (trace a letter freehand), and
  dictation (rebuild a spoken word from tiles)
- Short French explanations shown under wrong answers
- Units unlock sequentially as you complete the one before them
- A proverb tied to each unit, shown when its summary screen closes

**Duolingo-style progression mechanics**
- **Hearts** — a persistent, global pool (not per-lesson) that regenerates
  over time even while the app is closed, or can be refilled instantly with gems
- **Gems** — earned per lesson (with a bonus for a mistake-free run), spent on
  heart refills and streak freezes
- **XP & levels** — a levelling curve shown in the header and on your profile
- **Streaks** — daily streak tracking with purchasable streak freezes that
  silently cover one missed day
- **Daily goal** — a daily XP target (30 XP) with progress tracking
- **Unit chests** — a randomized gems/XP reward dialog the first time you
  clear a unit
- **Badges** — unlockable achievements (first lesson, 7-day streak, full
  alphabet, perfect lesson, full graduate)

**Beyond the main path**
- **Practice hub** — drill any unlocked unit on demand, without affecting
  path progress
- **Mistakes review** — letters you've gotten wrong are tracked and surfaced
  as a dedicated review session, like Duolingo's mistakes inbox
- **Spaced repetition** — a simplified SM-2 scheduler tracks each letter's
  ease and next-due date, and surfaces a "due for review" session whenever
  something needs reinforcing
- **Statistics** — global accuracy, total time spent, and a per-lesson
  accuracy breakdown; tapping a lesson there launches practice for it directly
- **Dialect preference** — pick maninka, bambara, or dioula in your profile;
  story episodes whose characters match your dialect are flagged
- **Audio glossary** — a searchable list of every letter/word taught so far,
  each with a "play" (TTS) button
- **League** — a weekly leaderboard. Uses a real Firebase backend when one
  is configured; otherwise falls back to a local, offline stand-in ranked
  against seeded bot scores
- **Friends** — add other players by pasting their id, see their weekly XP
  (requires the Firebase backend)
- **Club** — a single shared, join-by-code club with a collective weekly XP
  goal (requires the Firebase backend)
- **Lesson threads** — a per-unit discussion thread so learners can ask
  questions or share tips (requires the Firebase backend)
- **Profile** — stats, level progress, hearts, streak-freeze shop, dialect
  picker, a 7-day activity chart, and your badge case

**Story mode**
- "Saison 1" — a visual-novel-style narrative track running in parallel to
  the letters/units path: dialogue line by line in N'Ko with French
  subtitles, occasional branching choices, then a short comprehension quiz
- A short culture note shown once each episode wraps up
- Two episodes so far — more can be added by extending `story_data.dart`

## Firebase backend (social features)

League, Friends, Club, and Lesson threads are backed by Firestore + Anonymous
Auth. The app degrades gracefully without it — those screens show a
"non disponible" state instead of crashing, and everything else keeps
working. To point the app at your own Firebase project:

```
dart pub global activate flutterfire_cli
flutterfire configure
```

That overwrites `lib/firebase_options.dart` with real credentials (Firebase
client keys are meant to be public; access is controlled by the Firestore
security rules in `firestore.rules`, not by hiding the key). You'll also need
to enable the **Anonymous** sign-in provider in the Firebase console —
`flutterfire configure` and the `firebase` CLI don't expose that toggle.

## Audio (Djelia uniquement)

Tout l'audio passe par [Djelia](https://djelia.cloud) (synthèse vocale
bambara). Il n'y a **aucune voix de secours française** : sans clé ou en cas
d'échec réseau, l'app affiche un message au lieu de lire du faux avec un
accent français. Les annotations pédagogiques entre parenthèses
(« é (fermé) ») ne sont jamais lues.

```
flutter run -d chrome --dart-define=DJELIA_API_KEY=ta_cle
```

Une clé passée par `--dart-define` est lisible dans le binaire (surtout sur
le web). Pour une diffusion publique, déploie un petit proxy qui garde la clé
et passe son URL avec `--dart-define=DJELIA_TTS_URL=https://ton-proxy/tts`.

L'exercice de prononciation est désormais « écoute puis répète » (auto-évalué):
les reconnaissances vocales des appareils sont calées sur le français/anglais
et il n'existe pas de modèle N'Ko.

## Getting started

```
flutter pub get
flutter run -d chrome --dart-define=DJELIA_API_KEY=...   # ou -d windows / un appareil
flutter test
flutter build web --release --dart-define=DJELIA_API_KEY=...
```

## Project structure

```
lib/
  models/          N'Ko letter data, unit/exercise definitions, badge
                   catalog, story episodes, culture notes and proverbs
  services/        SocialService (Firebase-backed league/friends/club/
                   threads), VoiceService (TTS/best-effort pronunciation)
  state/           Persisted progress (hearts, gems, XP, streak, badges,
                   spaced-repetition state, stats…)
  theme/           Shared color palette and typography
  screens/         Path, lesson, practice, story, league, friends, club,
                   lesson threads, glossary, stats, profile, summary, failed
  widgets/         Reusable cards (quiz, match, word-bank, listening,
                   pronunciation, handwriting, dictation, chest dialog…)
  main.dart        App shell: bottom navigation + lesson state machine
```
