# Gamejoltodin integration example

This example uses [Gamejoltodin](https://github.com/flushwhy/Gamejoltodin) to authenticate a player, open a Game Jolt session, and submit a score.

## Setup

From the DapperO repository root:

- Linux/macOS: `sh scripts/setup_gamejoltodin.sh`
- Windows: run `scripts\setup_gamejoltodin.bat`

Set these environment variables in your shell before running:

- `GAMEJOLT_GAME_ID`
- `GAMEJOLT_PRIVATE_KEY`
- `GAMEJOLT_USERNAME`
- `GAMEJOLT_USER_TOKEN`

Then run:

```sh
odin run examples/gamejoltodin
```

The sample submits `100 points` with sort value `100` to the primary score table. Change those values and the table ID in the source for your game.

Do not commit real credentials or player tokens. Environment variables keep them out of source control, but a private key included in a distributed client can be extracted and is not a security boundary.
