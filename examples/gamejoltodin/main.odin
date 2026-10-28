package gamejoltodin_example

import fmt "core:fmt"
import os "core:os"
import gj "vendor:Gamejoltodin/gamejolt"

main :: proc() {
	game_id := os.get_env("GAMEJOLT_GAME_ID", context.temp_allocator)
	private_key := os.get_env("GAMEJOLT_PRIVATE_KEY", context.temp_allocator)
	username := os.get_env("GAMEJOLT_USERNAME", context.temp_allocator)
	user_token := os.get_env("GAMEJOLT_USER_TOKEN", context.temp_allocator)

	if game_id == "" || private_key == "" || username == "" || user_token == "" {
		fmt.println("Set GAMEJOLT_GAME_ID, GAMEJOLT_PRIVATE_KEY, GAMEJOLT_USERNAME, and GAMEJOLT_USER_TOKEN.")
		return
	}

	session := gj.gj_init(game_id, private_key)
	defer gj.gj_destroy(&session)

	user, err := gj.gj_login(&session, username, user_token)
	if err != .None {
		fmt.printfln("Game Jolt login failed: %v", err)
		return
	}
	defer gj.gj_user_delete(&user)

	fmt.printfln("Authenticated as %s (ID %d)", user.username, user.id)

	err = gj.gj_session_open(&session)
	if err != .None {
		fmt.printfln("Could not open Game Jolt session: %v", err)
		return
	}
	defer gj.gj_session_close(&session)

	err = gj.gj_scores_submit(&session, "100 points", 100)
	if err != .None {
		fmt.printfln("Score submission failed: %v", err)
		return
	}

	fmt.println("Submitted 100 points to the primary score table.")
}
