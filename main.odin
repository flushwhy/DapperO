package DapperO

import rl "vendor:raylib"
import fmt "core:fmt"

Animation :: struct {
	frame_rec:     rl.Rectangle, // The current frame rectangle
	frame_count:   i32, // Total frames in the sprite sheet
	current_frame: i32, // Current frame index
	update_time:   f32, // Time between frames
	running_time:  f32, // Accumulated time since last frame update
}

Window :: struct {
	title:         cstring,
	width:         i32,
	height:        i32,
	fps:           i32,
	control_flags: rl.ConfigFlags,
}

Nebula :: struct {
	texture:  rl.Texture2D,
	position: rl.Vector2,
	velocity: rl.Vector2,
	animation: Animation,
	rect:     rl.Rectangle,
}

Player :: struct {
	texture:       rl.Texture2D,
	position:      rl.Vector2,
	velocity:      rl.Vector2,
	is_in_air:     bool,
	gravity:       f32,
	jump_strength: f32,
	animation:      Animation,
	rect:          rl.Rectangle,
}

ParallaxLayer :: struct {
	texture: rl.Texture2D,
	x:       f32,
	speed:   f32,
}

Game :: struct {
	player:     Player,
	background: ParallaxLayer,
	midground:  ParallaxLayer,
	foreground: ParallaxLayer,
	window:     Window,
	delta_time: f32,
	elapsed_time: f32,
	is_running: bool,
}

draw_end_screen :: proc(elapsed_time: f32) {
	rl.DrawText(
		"Game Over!",
		rl.GetScreenWidth() / 2 - 100,
		rl.GetScreenHeight() / 2 - 50,
		40,
		rl.RED,
	)
	rl.DrawText(
		fmt.ctprintf("Survived: %.1f seconds", elapsed_time),
		rl.GetScreenWidth() / 2 - 130,
		rl.GetScreenHeight() / 2,
		20,
		rl.WHITE,
	)
	rl.DrawText(
		"Press [ENTER] to Restart",
		rl.GetScreenWidth() / 2 - 150,
		rl.GetScreenHeight() / 2 + 40,
		20,
		rl.WHITE,
	)
}

draw_nebulae :: proc(nebulae: []Nebula) {
	for n in nebulae {
		rl.DrawTextureRec(n.texture, n.animation.frame_rec, n.position, rl.WHITE)
	}
}

close_game :: proc(game: ^Game) {
	rl.UnloadTexture(game.player.texture)
	rl.UnloadTexture(game.background.texture)
	rl.UnloadTexture(game.midground.texture)
	rl.UnloadTexture(game.foreground.texture)
	rl.CloseWindow()
}

main :: proc() {
	// Initialize the window
	window := Window{"Dapper in Odin", 600, 350, 300, {.VSYNC_HINT, .WINDOW_RESIZABLE}}
	rl.InitWindow(window.width, window.height, window.title)
	rl.SetWindowState(window.control_flags)
	rl.SetTargetFPS(window.fps)

	// Initialize the game
	game := Game {
		player     = initialize_player("assets/scarfy.png", 1_000.0, -650.0, window.height),
		background = initialize_parallax_layer("assets/far-buildings.png", 15.0),
		midground  = initialize_parallax_layer("assets/back-buildings.png", 30.0),
		foreground = initialize_parallax_layer("assets/foreground.png", 60.0),
		window     = window,
		delta_time = 0.0,
		elapsed_time = 0.0,
		is_running = false,
	}

	nebula_texture := rl.LoadTexture("assets/12_nebula_spritesheet.png")
	nebulae := initialize_nebulae(nebula_texture, 10, f32(window.width) + 50.0, 300.0)
	defer close_game(&game)
	defer rl.UnloadTexture(nebula_texture)
	gj_state := gamejolt_init()
	defer gamejolt_shutdown(&gj_state)
	gamejolt_record_run(&gj_state)
	game.is_running = true
	// Main game loop
	for !rl.WindowShouldClose() {
		// Update delta time
		game.delta_time = rl.GetFrameTime()

		// Handle window resizing
		if rl.IsWindowResized() {
			game.window.width = rl.GetScreenWidth()
			game.window.height = rl.GetScreenHeight()
		}

		if game.is_running {
			game.elapsed_time += game.delta_time
			scroll_speed := min(200.0 + game.elapsed_time * 3.0, 520.0)

			cam := rl.Camera2D {
				zoom = f32(rl.GetScreenHeight()) / f32(window.height),
			}

			// Update simulation before checking collision so the first frame is valid too.
			update_player(&game.player, game.delta_time, game.window.height)
			update_nebulae(nebulae, game.delta_time, scroll_speed)

			for nebula in nebulae {
				if collides(nebula.rect, game.player.rect) {
					game.is_running = false
					gamejolt_record_death(&gj_state, int(game.elapsed_time))
					break
				}
			}
			update_parallax_layer(&game.background, game.delta_time)
			update_parallax_layer(&game.midground, game.delta_time)
			update_parallax_layer(&game.foreground, game.delta_time)

			// Draw the game
			rl.BeginDrawing()
			rl.ClearBackground(rl.RAYWHITE)
			rl.BeginMode2D(cam)
			// Draw parallax layers
			draw_parallax_layer(game.background, 2.0)
			draw_parallax_layer(game.midground, 2.0)
			draw_parallax_layer(game.foreground, 2.0)

			draw_nebulae(nebulae)
			rl.DrawText(fmt.ctprintf("Survived: %.1f s", game.elapsed_time), 12, 12, 20, rl.WHITE)
			// Draw player
			draw_player(game.player)
			rl.EndMode2D()
			rl.EndDrawing()
		} else {
			// Drawing: End Screen
			rl.BeginDrawing()
			rl.ClearBackground(rl.BLACK)
			draw_end_screen(game.elapsed_time)
			rl.EndDrawing()

			// Restart logic
			if rl.IsKeyPressed(.ENTER) {
				// Reinitialize game state
				delete(nebulae)
				nebulae = initialize_nebulae(nebula_texture, 10, f32(game.window.width) + 50.0, 300.0)
				game.elapsed_time = 0.0
				game.player.position = rl.Vector2{100.0, f32(game.window.height) - game.player.animation.frame_rec.height - 60.0}
				game.player.velocity = rl.Vector2{0.0, 0.0}
				game.player.is_in_air = false
				game.player.rect.x = game.player.position.x
				game.player.rect.y = game.player.position.y
				gamejolt_record_run(&gj_state)
				game.is_running = true
			}
		}
	}
	delete(nebulae)
}
