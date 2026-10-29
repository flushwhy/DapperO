# DapperO

A small 2D platformer built with [Odin](https://odin-lang.org/) and Raylib.

## Build

Use the same Odin dev compiler as CI: commit `84bc3fc2100b0f7880a3af37f71bccdcda41c6f9` (`dev-2026-10-nightly`). CI pins this exact compiler commit. To use it locally, check out that commit in your Odin compiler source tree and rebuild/install Odin.

Run the game with:

```sh
odin run .
```

For the optimized Windows build, run `release.bat`.

## Game Jolt API example

The [Gamejoltodin integration example](examples/gamejoltodin/README.md) demonstrates player authentication, session management, and leaderboard score submission. It uses a pinned copy of [Gamejoltodin](https://github.com/flushwhy/Gamejoltodin).

Set up the dependency with `sh scripts/setup_gamejoltodin.sh` on Linux/macOS or run `scripts\setup_gamejoltodin.bat` on Windows. Then follow the example guide to configure the environment and run `odin run examples/gamejoltodin`.

## Related links

- [Gamejoltodin source](https://github.com/flushwhy/Gamejoltodin)
- [Gamejoltodin documentation](https://flushwhy.github.io/Gamejoltodin/)
- [Gamejoltodin releases](https://github.com/flushwhy/Gamejoltodin/releases)
