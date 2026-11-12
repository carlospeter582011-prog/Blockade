# Blockade

A Flutter strategy board game for two people sharing an Android phone. It plays offline in portrait or landscape.

## Play

- Each player starts in the center of one edge of a 9 × 9 board and has ten walls.
- On your turn, move one square or place a wall. Tap a highlighted square to move. Jump an adjacent opponent if the space behind them is clear. If that square is blocked by a wall or the board edge, jump to an open square to either side of their pawn.
- Choose horizontal or vertical and tap the board, or drag a wall onto the board. Confirm the preview to place it. A wall spans two squares. Walls cannot cross, overlap, or eliminate either player's last route.
- The first player to reach any square on the opposite edge wins.

Rules references: [Blocade by Byk3y Studios](https://playblocade.com/) and [Gigamic's Quoridor rulebook](https://en.gigamic.com/modern-classics/107-quoridor.html).

## Run and build

Use Flutter 3.32.8 with the Android SDK and JDK 17 or 21.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
flutter build appbundle --release
```

## Automatic Android builds

Each push to `main` runs analysis and tests, then publishes `Blockade.apk` and `Blockade.aab` together in GitHub Releases. Both files are also available as an artifact in the Actions run. The Actions run number becomes the Android build number.

The workflow signs test builds with the runner's debug key by default. To use the same signing identity across releases, add these GitHub Actions repository secrets:

- `BLOCKADE_KEYSTORE_BASE64`: base64-encoded Android signing keystore
- `BLOCKADE_STORE_PASSWORD`: keystore password
- `BLOCKADE_KEY_ALIAS`: alias of the signing key
- `BLOCKADE_KEY_PASSWORD`: signing key password
