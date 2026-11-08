# Mathra Pipes Game

Connect the pipes… clear the level! Flutter (Android) puzzle game by **Denuwan Akash**.

Based on the open-source *Pipes* game by sidhant947 (GPL-3.0, see `LICENSE`).

## Features
- 3D dashboard on the home screen (floating logo you can tilt, 3D tiles)
- Game screen that fits every phone size: board panel, stats, and a button dock
  (Hint, Music, Effects, Ranks, Restart) with a mini music player
- 3D glossy pipes with strong contrast on every theme (16 themes)
- Effects you can switch: emoji rain, confetti, both or off + emoji packs + speed
- Settings organised in cards: Language, Theme, Gameplay, Effects, Music & Download, Player
- Playlist: paste a YouTube link, the audio is downloaded with several parallel
  connections (fast) and added automatically. Quality: Fast / Normal / High,
  with speed and time-left shown
- Local 3D leaderboard (names + scores of everyone who plays on the device)

## Build
```
flutter pub get
flutter build apk --release
```
Without `android/key.properties` the release APK is signed with the debug key.
