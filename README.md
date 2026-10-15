# DapperO — Odin Platformer + Game Jolt Example

DapperO is a small Raylib platformer written in Odin. It also demonstrates calling the **native Odin Game Jolt API** from gameplay code: the library owns its Odin strings and session state, while DapperO uses ordinary Odin types and error returns.

## Game Jolt features demonstrated

- Login and open/close an online session.
- Submit each survival duration to the primary leaderboard.
- Track player-scoped `runs` and `deaths` values in the Game Jolt data store.
- Optionally unlock a survival milestone trophy after the configured duration.
- Keep the game playable offline while the integration still has placeholder credentials.

## Setup

1. Clone DapperO with its Gamejoltodin submodule:

   ```sh
   git clone --recurse-submodules https://github.com/flushwhy/DapperO.git
   ```

   If DapperO is already cloned without its submodule, initialize it with:

   ```sh
   git submodule update --init --recursive
   ```

   The submodule pins the native API revision used by this example, so the package and API stay in sync.

2. In `gamejolt_integration.odin`, replace the placeholder game ID, private key, username, and user token with your Game Jolt values. Do not commit real credentials. Set `GAMEJOLT_SURVIVAL_TROPHY_ID` and `GAMEJOLT_SURVIVAL_TROPHY_SECONDS` to configure an optional survival milestone; leave the ID at `0` to disable it.

3. Install Odin and ensure the dependencies required by both projects are available. DapperO uses the Raylib vendor package; Gamejoltodin uses its vendored curl bindings and the platform's curl dependencies.

4. From the DapperO directory, run:

   ```sh
   odin run . -collection:gamejolt=Gamejoltodin
   ```

   The collection mapping makes the library's `gamejolt` package available as `gamejolt:gamejolt`. The example calls the library directly; it does not use the C ABI.

## Controls

- **Space** — jump
- **Enter** — restart after game over

## Integration notes

Dapper is an endless survival game: hazards recycle with increasing speed until the player collides. The example submits survival duration to a primary-table score; configure that table to sort by the numeric value as appropriate for your leaderboard. Replace the placeholder IDs and credentials with values from your own Game Jolt game before expecting online calls to succeed.

See [Gamejoltodin](https://github.com/flushwhy/Gamejoltodin) for the library API, C ABI, error codes, and ownership rules.
