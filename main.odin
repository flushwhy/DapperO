package DapperO

import rl "vendor:raylib"
import time "core:time"

Window :: struct {
	title:         cstring,
	width:         i32,
	height:        i32,
	fps:           i32,
	control_flags: rl.ConfigFlags,
}

Player :: struct {
	texture:       rl.Texture2D,
	position:      rl.Vector2,
	velocity:      rl.Vector2,
	is_in_air:     bool,
	gravity:       f32,
	jump_strength: f32,
}

ParallaxLayer :: struct {
	texture: rl.Texture2D,
	x:       f32,
	speed:   f32,
}

Game :: struct {
	player:          Player,
	background:      ParallaxLayer,
	midground:       ParallaxLayer,
	foreground:      ParallaxLayer,
	window:          Window,
	delta_time:      f32,
}

initialize_player :: proc(filepath: cstring, gravity: f32, jump_strength: f32) -> Player {
	texture := rl.LoadTexture(filepath)
	return Player{
		texture = texture,
		position = rl.Vector2{ 100.0, 380.0 - f32(texture.height)},
		velocity = rl.Vector2{ 0.0, 0.0},
		is_in_air = false,
		gravity = gravity,
		jump_strength = jump_strength,
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
	if player.position.y >= f32(window_height - player.texture.height) {
		player.position.y = f32(window_height - player.texture.height)
		player.velocity.y = 0
		player.is_in_air = false
	}

	// Jump
	if rl.IsKeyPressed(.SPACE) && !player.is_in_air {
		player.velocity.y = player.jump_strength
		player.is_in_air = true
	}
}

update_parallax_layer :: proc(layer: ^ParallaxLayer, dt: f32, window_width: i32) {
	layer.x -= layer.speed * dt
	if layer.x <= -f32(layer.texture.width * 2) {
		layer.x = 0.0
	}
}

draw_parallax_layer :: proc(layer: ParallaxLayer, scale: f32) {
	rl.DrawTextureEx(layer.texture, rl.Vector2{layer.x, 0}, 0.0, scale, rl.WHITE)
	rl.DrawTextureEx(layer.texture, rl.Vector2{layer.x + f32(layer.texture.width) * scale, 0}, 0.0, scale, rl.WHITE)
}

draw_player :: proc(player: Player) {
	rl.DrawTexture(player.texture, i32(player.position.x), i32(player.position.y), rl.WHITE)
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
	window := Window{"Side Scroller", 800, 600, 60, {.WINDOW_RESIZABLE}}
	rl.InitWindow(window.width, window.height, window.title)
	rl.SetWindowState(window.control_flags)
	rl.SetTargetFPS(window.fps)

	// Initialize the game
	game := Game{
		player = initialize_player("assets/scarfy.png", 1_000.0, -600.0),
		background = initialize_parallax_layer("assets/back-buildings.png", 20.0),
		midground = initialize_parallax_layer("assets/far-buildings.png", 40.0),
		foreground = initialize_parallax_layer("assets/foreground.png", 60.0),
		window = window,
		delta_time = 0.0,
	}

	defer close_game(&game)

	// Main game loop
	for !rl.WindowShouldClose() {
		// Update delta time
		game.delta_time = rl.GetFrameTime()

		// Handle window resizing
		if rl.IsWindowResized() {
			game.window.width = rl.GetScreenWidth()
			game.window.height = rl.GetScreenHeight()
		}

		// Update game logic
		update_player(&game.player, game.delta_time, game.window.height)
		update_parallax_layer(&game.background, game.delta_time, game.window.width)
		update_parallax_layer(&game.midground, game.delta_time, game.window.width)
		update_parallax_layer(&game.foreground, game.delta_time, game.window.width)

		// Draw the game
		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		// Draw parallax layers
		draw_parallax_layer(game.background, 2.0)
		draw_parallax_layer(game.midground, 2.0)
		draw_parallax_layer(game.foreground, 2.0)

		// Draw player
		draw_player(game.player)

		rl.EndDrawing()
	}
}

