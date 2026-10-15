# DapperO — Odin Platformer + Game Jolt Example

DapperO is a small Raylib platformer written in Odin. It also demonstrates calling the **native Odin Game Jolt API** from gameplay code: the library owns its Odin strings and session state, while DapperO uses ordinary Odin types and error returns.

## Game Jolt features demonstrated

- Login and open/close an online session.
- Submit a completion-time score to the primary leaderboard.
- Track player-scoped `runs`, `wins`, and `deaths` values in the Game Jolt data store.
- Optionally unlock a win trophy when a trophy ID is configured.
- Keep the game playable offline while the integration still has placeholder credentials.

## Setup

1. Clone both repositories next to each other:

   ```text
   workspace/
     DapperO/
     Gamejoltodin/
   ```

   Until the native-session change in Gamejoltodin is merged, check out its `feat/odin-first` branch in that clone. After it lands, use the default branch.

2. In `gamejolt_integration.odin`, replace the placeholder game ID, private key, username, and user token with your Game Jolt values. Do not commit real credentials. Set `GAMEJOLT_WIN_TROPHY_ID` to a real trophy ID to enable trophy unlocking; leave it at `0` to disable that feature.

3. Install Odin and ensure the dependencies required by both projects are available. DapperO uses the Raylib vendor package; Gamejoltodin uses its vendored curl bindings and the platform's curl dependencies.

4. From the DapperO directory, run:

   ```sh
   odin run . -collection:gamejolt=../Gamejoltodin
   ```

   The collection mapping makes the library's `gamejolt` package available as `gamejolt:gamejolt`. The example calls the library directly; it does not use the C ABI.

## Controls

- **Space** — jump
- **Enter** — restart after a win or game over

## Integration notes

The example uses a primary-table score with the elapsed run time as the numeric sort value (lower is faster). Replace the placeholder IDs and credentials with values from your own Game Jolt game before expecting online calls to succeed.

See [Gamejoltodin](https://github.com/flushwhy/Gamejoltodin) for the library API, C ABI, error codes, and ownership rules.
