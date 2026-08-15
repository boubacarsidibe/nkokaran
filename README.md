# N'Ko Kalan

A Flutter app for learning to read and write N'Ko (ߒߞߏ) — the Manding-language
alphabet — built as a Duolingo-style gamified learning loop.

## Features

**Learning path**
- 7 units: vowels, four consonant groups, digits, and a "first word" capstone
- Three exercise types per lesson: multiple-choice (character↔sound), a
  match-the-pairs checkpoint, and a tile-tap word-bank exercise
- Units unlock sequentially as you complete the one before them

**Duolingo-style progression mechanics**
- **Hearts** — a persistent, global pool (not per-lesson) that regenerates
  over time even while the app is closed, or can be refilled instantly with gems
- **Gems** — earned per lesson (with a bonus for a mistake-free run), spent on
  heart refills and streak freezes
- **XP & levels** — a levelling curve shown in the header and on your profile
- **Streaks** — daily streak tracking with purchasable streak freezes that
  silently cover one missed day
- **Daily goal** — a configurable daily XP target with progress tracking
- **Unit chests** — a randomized gems/XP reward dialog the first time you
  clear a unit
- **Badges** — unlockable achievements (first lesson, 7-day streak, full
  alphabet, perfect lesson, full graduate)

**Beyond the main path**
- **Practice hub** — drill any unlocked unit on demand, without affecting
  path progress
- **Mistakes review** — letters you've gotten wrong are tracked and surfaced
  as a dedicated review session, like Duolingo's mistakes inbox
- **League** — a local, offline weekly leaderboard (seeded bots + your own
  weekly XP, since there's no backend here)
- **Profile** — stats, level progress, hearts, streak-freeze shop, a 7-day
  activity chart, and your badge case

## Getting started

```
flutter pub get
flutter run -d chrome    # or -d windows, or any connected device
```

## Project structure

```
lib/
  models/          N'Ko letter data, unit/exercise definitions, badge catalog
  state/           Persisted progress (hearts, gems, XP, streak, badges…)
  theme/           Shared color palette and typography
  screens/         Path, lesson, practice, league, profile, summary, failed
  widgets/         Reusable cards (quiz, match, word-bank, chest dialog, etc.)
  main.dart        App shell: bottom navigation + lesson state machine
```
