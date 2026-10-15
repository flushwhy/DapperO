package DapperO

//import "core:time"
import rl "vendor:raylib"
import fmt "core:fmt"

Anim :: struct {
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
	AnimData: Anim,
	rect:     rl.Rectangle,
}

Player :: struct {
	texture:       rl.Texture2D,
	position:      rl.Vector2,
	velocity:      rl.Vector2,
	is_in_air:     bool,
	gravity:       f32,
	jump_strength: f32,
	AnimData:      Anim,
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
}

// AABB collision detection
collides :: proc(a: rl.Rectangle, b: rl.Rectangle) -> bool {
	return(
		a.x < b.x + b.width &&
		a.x + a.width > b.x &&
		a.y < b.y + b.height &&
		a.y + a.height > b.y \
	)
}

initialize_player :: proc(filepath: cstring, gravity: f32, jump_strength: f32) -> Player {
	texture := rl.LoadTexture(filepath)
	anim := Anim {
		frame_rec     = rl.Rectangle{0, 0, f32(texture.width) / 6, f32(texture.height)}, // Assuming 6 frames horizontally
		frame_count   = 6,
		current_frame = 0,
		update_time   = 1.0 / 12.0, // 12 FPS
		running_time  = 0.0,
	}

	return Player {
		texture = texture,
		position = rl.Vector2{100.0, 380.0 - f32(texture.height)},
		velocity = rl.Vector2{0.0, 0.0},
		is_in_air = false,
		gravity = gravity,
		jump_strength = jump_strength,
		AnimData = anim,
		rect = rl.Rectangle{0, 0, f32(texture.width) / 6, f32(texture.height)},
	}
}

initialize_parallax_layer :: proc(filepath: cstring, speed: f32) -> ParallaxLayer {
	texture := rl.LoadTexture(filepath)
	return ParallaxLayer{texture = texture, x = 0.0, speed = speed}
}

update_player :: proc(player: ^Player, dt: f32, window_height: i32) {
	player.velocity.y += player.gravity * dt

	// Apply vertical movement
	player.position.y += player.velocity.y * dt

	// Check if player hits the ground
	if player.position.y >=   225 {
		player.position.y =  225
		fmt.println("Player hit the ground ", player.position.y)
		player.velocity.y = 0
		player.is_in_air = false
	}

	// Jump
	if rl.IsKeyPressed(.SPACE) && !player.is_in_air {
		player.velocity.y = player.jump_strength
		player.is_in_air = true
	}

	if !player.is_in_air {
		player.AnimData.running_time += dt
		if player.AnimData.running_time >= player.AnimData.update_time {
			player.AnimData.running_time = 0.0
			player.AnimData.current_frame =
				(player.AnimData.current_frame + 1) % player.AnimData.frame_count
			player.AnimData.frame_rec.x =
				f32(player.AnimData.current_frame) * player.AnimData.frame_rec.width
		}
	}

	player.rect.x = player.position.x
	player.rect.y = player.position.y
}

initialize_nebulae :: proc(
	texture: rl.Texture2D,
	count: i32,
	start_x: f32,
	spacing: f32,
) -> []Nebula {
	nebulae: []Nebula = make([]Nebula, count)

	frame_width := f32(texture.width) / 8
	frame_height := f32(texture.height) / 8

	for i in 0 ..< count {
		anim := Anim {
			frame_rec     = rl.Rectangle{0, 0, frame_width, frame_height},
			frame_count   = 8,
			current_frame = 0,
			update_time   = 1.0 / 16.0, // 16 FPS
			running_time  = 0.0,
		}

		nebulae[i] = Nebula {
			texture  = texture,
			position = rl.Vector2{start_x + spacing * f32(i), 380.0 - frame_height},
			velocity = rl.Vector2{-200.0, 0.0},
			AnimData = anim,
			rect     = rl.Rectangle {
				start_x + spacing * f32(i),
				380.0 - frame_height,
				frame_width,
				frame_height,
			},
		}
	}

	return nebulae
}

draw_player :: proc(player: Player) {
	rl.DrawTextureRec(
		player.texture,
		player.AnimData.frame_rec,
		rl.Vector2{player.position.x, player.position.y},
		rl.WHITE,
	)
}

update_parallax_layer :: proc(layer: ^ParallaxLayer, dt: f32, window_width: i32) {
	layer.x -= layer.speed * dt
	if layer.x <= -f32(layer.texture.width) * 2 {
		layer.x = 0.0
	}
}

draw_parallax_layer :: proc(layer: ParallaxLayer, scale: f32) {
	rl.DrawTextureEx(layer.texture, rl.Vector2{layer.x, 0}, 0.0, scale, rl.WHITE)
	rl.DrawTextureEx(
		layer.texture,
		rl.Vector2{layer.x + f32(layer.texture.width) * scale, 0},
		0.0,
		scale,
		rl.WHITE,
	)
}

// Move hazards continuously and recycle each one after it leaves the screen.
// The gap pattern is deterministic for now, which makes runs easier to tune and test.
update_nebulae :: proc(nebulae: []Nebula, dt, scroll_speed: f32) {
	for &n in nebulae {
		n.velocity.x = -scroll_speed
		n.position.x += n.velocity.x * dt
		n.rect.x = n.position.x
		n.rect.y = n.position.y
		n.rect.width = n.AnimData.frame_rec.width
		n.rect.height = n.AnimData.frame_rec.height

		n.AnimData.running_time += dt
		for n.AnimData.running_time >= n.AnimData.update_time {
			n.AnimData.running_time -= n.AnimData.update_time
			n.AnimData.current_frame = (n.AnimData.current_frame + 1) % n.AnimData.frame_count
			n.AnimData.frame_rec.x = f32(n.AnimData.current_frame) * n.AnimData.frame_rec.width
		}
	}

	for i in 0 ..< len(nebulae) {
		n := &nebulae[i]
		if n.position.x + n.rect.width < 0 {
			rightmost := f32(rl.GetScreenWidth())
			for other in nebulae {
				if other.position.x + other.rect.width > rightmost {
					rightmost = other.position.x + other.rect.width
				}
			}
			// Vary the spacing without depending on a random seed or global RNG.
			gap := 220.0 + f32((i * 73) % 140)
			n.position.x = rightmost + gap
			n.rect.x = n.position.x
		}
	}
}

draw_hud :: proc(elapsed_time, scroll_speed: f32) {
	rl.DrawText(fmt.tprintf("Survived: %.1f s", elapsed_time), 16, 12, 20, rl.WHITE)
	rl.DrawText(fmt.tprintf("Speed: %.0f", scroll_speed), 16, 36, 16, rl.WHITE)
}

draw_end_screen :: proc() {
	rl.DrawText(
		"Game Over!",
		rl.GetScreenWidth() / 2 - 100,
		rl.GetScreenHeight() / 2 - 50,
		40,
		rl.RED,
	)
	rl.DrawText(
		"Press [ENTER] to Restart",
		rl.GetScreenWidth() / 2 - 150,
		rl.GetScreenHeight() / 2 + 10,
		20,
		rl.WHITE,
	)
}

draw_nebulae :: proc(nebulae: []Nebula) {
	for n in nebulae {
		rl.DrawTextureRec(n.texture, n.AnimData.frame_rec, n.position, rl.WHITE)
	}
}

close_game :: proc(game: ^Game) {
	rl.UnloadTexture(game.player.texture)
	rl.UnloadTexture(game.background.texture)
	rl.UnloadTexture(game.midground.texture)
	rl.UnloadTexture(game.foreground.texture)
	rl.CloseWindow()
}

running: bool

main :: proc() {
	// Initialize the window
	window := Window{"Dapper in Odin", 600, 350, 300, {.VSYNC_HINT, .WINDOW_RESIZABLE}}
	rl.InitWindow(window.width, window.height, window.title)
	rl.SetWindowState(window.control_flags)
	rl.SetTargetFPS(window.fps)

	// Initialize the game
	game := Game {
		player     = initialize_player("assets/scarfy.png", 1_000.0, -650.0),
		background = initialize_parallax_layer("assets/far-buildings.png", 15.0),
		midground  = initialize_parallax_layer("assets/back-buildings.png", 30.0),
		foreground = initialize_parallax_layer("assets/foreground.png", 60.0),
		window     = window,
		delta_time = 0.0,
		elapsed_time = 0.0,
	}

	nebula_texture := rl.LoadTexture("assets/12_nebula_spritesheet.png")
	nebulae := initialize_nebulae(nebula_texture, 10, 640.0, 450.0)
	defer delete(nebulae)

	defer close_game(&game)
	gj_state := gamejolt_init()
	defer gamejolt_shutdown(&gj_state)
	gamejolt_record_run(&gj_state)
	running = true
	// Main game loop
	for !rl.WindowShouldClose() {
		// Update delta time
		game.delta_time = rl.GetFrameTime()

		// Handle window resizing
		if rl.IsWindowResized() {
			game.window.width = rl.GetScreenWidth()
			game.window.height = rl.GetScreenHeight()
		}

		if running {
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
					running = false
					gamejolt_record_death(&gj_state)
					break
				}
			}
			update_parallax_layer(&game.background, game.delta_time, game.window.width)
			update_parallax_layer(&game.midground, game.delta_time, game.window.width)
			update_parallax_layer(&game.foreground, game.delta_time, game.window.width)

			// Draw the game
			rl.BeginDrawing()
			rl.ClearBackground(rl.RAYWHITE)
			rl.BeginMode2D(cam)
			// Draw parallax layers
			draw_parallax_layer(game.background, 2.0)
			draw_parallax_layer(game.midground, 2.0)
			draw_parallax_layer(game.foreground, 2.0)

			draw_nebulae(nebulae)
			rl.DrawText(fmt.tprintf("Survived: %.1f s", game.elapsed_time), 12, 12, 20, rl.WHITE)
			// Draw player
			draw_player(game.player)
			rl.EndMode2D()
			rl.EndDrawing()
		} else {
			// Drawing: End Screen
			rl.BeginDrawing()
			rl.ClearBackground(rl.BLACK)
			draw_end_screen()
			rl.EndDrawing()

			// Restart logic
			if rl.IsKeyPressed(.ENTER) {
				// Reinitialize game state
				delete(nebulae)
				nebulae = initialize_nebulae(nebula_texture, 10, 640.0, 450.0)
				game.elapsed_time = 0.0
				game.player.position = rl.Vector2{100.0, 380.0 - f32(game.player.texture.height)}
				game.player.velocity = rl.Vector2{0.0, 0.0}
				game.player.is_in_air = false
				gamejolt_record_run(&gj_state)
				running = true
			}
		}
	}
}

