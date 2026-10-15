package DapperO

import fmt "core:fmt"
import gj "gamejolt:gamejolt"

// Replace these placeholders locally with your Game Jolt game's credentials.
// Do not commit real private keys or player tokens.
GAMEJOLT_GAME_ID :: "YOUR_GAME_ID"
GAMEJOLT_PRIVATE_KEY :: "YOUR_PRIVATE_KEY"
GAMEJOLT_USERNAME :: "YOUR_USERNAME"
GAMEJOLT_USER_TOKEN :: "YOUR_USER_TOKEN"

// Optional trophy for surviving this many seconds. Set the ID to 0 to disable it.
GAMEJOLT_SURVIVAL_TROPHY_ID :: 0
GAMEJOLT_SURVIVAL_TROPHY_SECONDS :: 60

GameJolt_State :: struct {
    session:   gj.GJ_Session,
    logged_in: bool,
}

// Initializes the native Odin Game Jolt API. If credentials are still the
// placeholders, the game runs offline and the integration remains disabled.
gamejolt_init :: proc() -> GameJolt_State {
    state: GameJolt_State
    state.session = gj.gj_init(GAMEJOLT_GAME_ID, GAMEJOLT_PRIVATE_KEY)

    if GAMEJOLT_GAME_ID == "YOUR_GAME_ID" ||
       GAMEJOLT_PRIVATE_KEY == "YOUR_PRIVATE_KEY" ||
       GAMEJOLT_USERNAME == "YOUR_USERNAME" ||
       GAMEJOLT_USER_TOKEN == "YOUR_USER_TOKEN" {
        fmt.println("[GameJolt] Configure credentials in gamejolt_integration.odin to enable online features.")
        return state
    }

    user, err := gj.gj_login(&state.session, GAMEJOLT_USERNAME, GAMEJOLT_USER_TOKEN)
    if err != .None {
        fmt.printfln("[GameJolt] Login failed: %v", err)
        return state
    }
    gj.gj_user_delete(&user)

    state.logged_in = true
    session_err := gj.gj_session_open(&state.session)
    if session_err != .None {
        fmt.printfln("[GameJolt] Could not open online session: %v", session_err)
    }

    return state
}

// Counts each attempt, including attempts after a restart.
gamejolt_record_run :: proc(state: ^GameJolt_State) {
    if !state.logged_in do return
    _, err := gj.gj_data_increment(&state.session, "runs", 1, user = true)
    if err != .None do fmt.printfln("[GameJolt] Could not update run count: %v", err)
}

// Records a completed survival run, including its score and player statistics.
gamejolt_record_death :: proc(state: ^GameJolt_State, elapsed_seconds: int) {
    if !state.logged_in do return

    score_text := fmt.tprintf("%d seconds survived", elapsed_seconds)
    defer delete(score_text)
    score_err := gj.gj_scores_submit(&state.session, score_text, elapsed_seconds, 0, "DapperO")
    if score_err != .None do fmt.printfln("[GameJolt] Score submission failed: %v", score_err)

    _, data_err := gj.gj_data_increment(&state.session, "deaths", 1, user = true)
    if data_err != .None do fmt.printfln("[GameJolt] Could not update death count: %v", data_err)

    if GAMEJOLT_SURVIVAL_TROPHY_ID > 0 && elapsed_seconds >= GAMEJOLT_SURVIVAL_TROPHY_SECONDS {
        trophy_err := gj.gj_trophy_unlock(&state.session, GAMEJOLT_SURVIVAL_TROPHY_ID)
        if trophy_err != .None do fmt.printfln("[GameJolt] Survival trophy unlock failed: %v", trophy_err)
    }
}

// Release the native session's Odin-owned strings when the game exits.
gamejolt_shutdown :: proc(state: ^GameJolt_State) {
    if state.logged_in {
        err := gj.gj_session_close(&state.session)
        if err != .None do fmt.printfln("[GameJolt] Session close failed: %v", err)
    }
    gj.gj_destroy(&state.session)
}
