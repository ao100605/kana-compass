# Kana Compass

Kana Compass is an iOS app for learning to type Japanese hiragana the way a real phone does — with the flick gestures used on the standard Japanese flick keyboard, instead of a full alphabet keyboard.

Each of the ten gojūon rows (あ, か, さ, た, な, は, ま, や, ら, わ) lives on a single key. Tap the center for that row's base kana, or flick up, down, left, or right to reach the other four — the same mechanic used to type Japanese on a real phone keyboard.

## Features

- **Compass Practice** — flick a single tile in the direction that matches the kana you're shown, with a **Training** stage that labels each direction and a **Practice** stage that hides them.
- **Keyboard Grid** — the full flick keyboard laid out at once; find and flick the right key for the target kana.
- **Typing Practice** — type real hiragana words and sentences using the flick keyboard, with an optional toggle for dakuten, handakuten, and small-kana forms (が, ぱ, っ, etc.).
- **Time Attack** — a scored, timed challenge (30 / 60 / 120s) across everything at once, with a best score tracked per duration.
- **Row selection** — choose which of the ten rows to include in any practice mode.
- **Guided welcome flow** — a first-launch walkthrough explaining the flick mechanic and the four modes, with an interactive tile you can drag to try the gesture yourself.

## Requirements

- Xcode 26 or later
- iOS 26.0+ (simulator or device)

## Getting started

```bash
git clone https://github.com/ao100605/kana-compass.git
cd kana-compass
open "Kana Compass.xcodeproj"
```

Select a simulator or a connected device as the run destination and press **Cmd+R**.

## Project structure

```
Kana Compass/
├── Kana_CompassApp.swift      # App entry point, loading → welcome → main screen flow
├── Models/
│   ├── KanaData.swift         # Kana rows, flick directions, keyboard layout, mark cycles
│   └── TypingContent.swift    # Word/sentence pools for Typing Practice and Time Attack
├── Screens/
│   ├── ContentView.swift      # Main screen: mode switcher and shared controls
│   └── WelcomeView.swift      # First-launch onboarding carousel
├── Views/
│   ├── LoadingView.swift
│   ├── PracticeViewModel.swift  # Shared state and scoring logic for all modes
│   ├── PracticeViews.swift      # Compass Practice and shared row/stage controls
│   ├── KeyboardGridView.swift
│   ├── TypingPracticeView.swift
│   └── TimeAttackView.swift
└── Assets.xcassets/
```

## Tech

Built entirely in SwiftUI with no external dependencies. Practice progress (selected rows, stage, best Time Attack scores, etc.) is persisted locally with `UserDefaults`.
