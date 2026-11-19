# Life Counter (Flutter)

A colorful life counter for 1–6 players, with rotated panels for everyone around the table.

## Run it

1. Install Flutter: https://docs.flutter.dev/get-started/install/windows
2. In this folder, create the Android/iOS platform folders (your existing `lib/` and `test/` files are kept):

   ```powershell
   flutter create . --project-name life_counter --platforms android,ios
   ```

3. Get packages, run the tests, then start the app on a phone or emulator:

   ```powershell
   flutter pub get
   ```

   ```powershell
   flutter test
   ```

   ```powershell
   flutter run
   ```

**Android release builds:** the fonts are downloaded at runtime (google_fonts), so add
`<uses-permission android:name="android.permission.INTERNET"/>` to
`android/app/src/main/AndroidManifest.xml`. Debug builds already have it.

## How it works

- Tap the **right half** of a panel for +1 and the **left half** for −1.
- **Hold** for +10 / −10. It keeps repeating while you hold.
- The small number above a total shows the change from the last 2 seconds.
- The **center hexagon** opens the ring menu:
  - **Restart**: resets everyone to the starting life
  - **High Roll**: each player gets a d20 (no ties). The winner stays white. Tap ✕ to close.
  - **Dice**: coin, D4, D6, D8, D10, D12, D20
  - **Settings**: starting life (20/25/30/40/50) and keep the screen awake
  - **Players**: pick 1–6 players and a table layout
  - **Help**

## Code

- `lib/game_state.dart`: players, life changes, high roll
- `lib/layouts.dart`: table layouts (each panel's rotation)
- `lib/screens/`: game, players, settings, dice
- `lib/widgets/`: player panel, hexagon button, ring menu
