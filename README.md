# LeadSheetMaker

A cross-platform GUI application for creating lead sheets — simple musical notation with lyrics and chord symbols positioned above them.

## What is a Lead Sheet?

A lead sheet is a form of musical notation that shows:
- **Lyrics** — the words to a song
- **Chord symbols** — positioned above the lyrics exactly where chord changes occur

Example:
```
    G        Em       C         D
Amazing grace, how sweet the sound
     G        Em    C       G
That saved a wretch like me
```

## Features

- **Easy chord positioning** — Click on any position in the lyrics to place a chord
- **Drag-and-drop** — Reposition chords by dragging them
- **Multiple songs** — Create and manage multiple lead sheets
- **Export options** — Export as PDF, plain text, or image
- **Cross-platform** — Runs on macOS, iOS, Windows, and Web

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/wilcantrell/lead_sheet_maker.git
   cd lead_sheet_maker
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   # macOS
   flutter run -d macos
   
   # iOS
   flutter run -d ios
   
   # Windows
   flutter run -d windows
   
   # Web
   flutter run -d chrome
   ```

## Usage

1. **Add lyrics** — Type or paste your song lyrics
2. **Add chords** — Click above any word/syllable to place a chord symbol
3. **Edit chords** — Click on a chord to change it, or drag to reposition
4. **Save/Export** — Save your work and export in your preferred format

## Roadmap

- [x] Basic lyrics editor
- [x] Chord placement system
- [x] Drag-and-drop chord repositioning
- [x] Save/load lead sheets (JSON format)
- [ ] PDF export
- [x] Plain text export
- [ ] Transpose function
- [ ] Chord library/suggestions
- [ ] Print support

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

Wil Cantrell
