package DapperO

import rl "vendor:raylib"
import time "core:time"

Anim :: struct {
    frame_rec:   rl.Rectangle, // The current frame rectangle
    frame_count: i32,          // Total frames in the sprite sheet
    current_frame: i32,        // Current frame index
    update_time:  f32,         // Time between frames
    running_time: f32,         // Accumulated time since last frame update
}

Window :: struct {
	title:         cstring,
	width:         i32,
	height:        i32,
	fps:           i32,
	control_flags: rl.ConfigFlags,
}

Nebula :: struct {
    texture:       rl.Texture2D,
    position:      rl.Vector2,
    velocity:      rl.Vector2,
    AnimData:      Anim,
	rect:          rl.Rectangle,
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
	player:          Player,
	background:      ParallaxLayer,
	midground:       ParallaxLayer,
	foreground:      ParallaxLayer,
	window:          Window,
	delta_time:      f32,
}

// AABB collision detection
collides :: proc(a: rl.Rectangle, b: rl.Rectangle) -> bool {
    return a.x < b.x + b.width && a.x + a.width > b.x &&
           a.y < b.y + b.height && a.y + a.height > b.y
}

initialize_player :: proc(filepath: cstring, gravity: f32, jump_strength: f32) -> Player {
	texture := rl.LoadTexture(filepath)
	anim := Anim{
		frame_rec = rl.Rectangle{0, 0, f32(texture.width) / 6, f32(texture.height)}, // Assuming 8 frames horizontally
        frame_count = 6,
        current_frame = 0,
        update_time = 1.0 / 12.0, // 12 FPS
        running_time = 0.0,
	}
	
	return Player{
		texture = texture,
		position = rl.Vector2{ 100.0, 380.0 - f32(texture.height)},
		velocity = rl.Vector2{ 0.0, 0.0},
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

	if !player.is_in_air {
        player.AnimData.running_time += dt
        if player.AnimData.running_time >= player.AnimData.update_time {
            player.AnimData.running_time = 0.0
            player.AnimData.current_frame = (player.AnimData.current_frame + 1) % player.AnimData.frame_count
            player.AnimData.frame_rec.x = f32(player.AnimData.current_frame) * player.AnimData.frame_rec.width
        }
    }

	player.rect.x = player.position.x
    player.rect.y = player.position.y
}

initialize_nebulae :: proc(texture: rl.Texture2D, count: i32, start_x: f32, spacing: f32) -> []Nebula {
	nebulae: []Nebula = make([]Nebula, count)

	frame_width := f32(texture.width) / 8
	frame_height := f32(texture.height) / 8

	for i in 0..<count {
		anim := Anim{
            frame_rec = rl.Rectangle{0, 0, frame_width, frame_height},
            frame_count = 8,
            current_frame = 0,
            update_time = 1.0 / 16.0, // 16 FPS
            running_time = 0.0,
		}

		nebulae[i] = Nebula{
			texture = texture,
			position = rl.Vector2{ start_x + spacing * f32(i), 380.0 - frame_height},
			velocity = rl.Vector2{ -200.0, 0.0},
			AnimData = anim,
			rect = rl.Rectangle{start_x + spacing * f32(i), 380.0 - frame_height, frame_width, frame_height},
		}
	}

	return nebulae
}

draw_player :: proc(player: Player) {
	rl.DrawTextureRec(
		player.texture,
		player.AnimData.frame_rec,
		rl.Vector2{player.position.x, player.position.y},
		rl.WHITE
	)
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

update_nebulae :: proc(nebulae: []Nebula, dt: f32, windowWidth: i32) -> bool {
    all_off_screen := true

    for &n in nebulae {
        // Update position
        n.position.x += n.velocity.x * dt

        // Check if the nebula is still visible
        if n.position.x + n.AnimData.frame_rec.width > 0 {
            all_off_screen = false
        }

		n.rect.x = n.position.x
		n.rect.y = n.position.y
		n.rect.width = n.AnimData.frame_rec.width / 8
		n.rect.height = n.AnimData.frame_rec.height / 8
		// Handle the boundaries or any other conditions
		if n.position.x < 0 || n.position.x > f32(windowWidth + 100) {
			n.velocity.x = -n.velocity.x // Reverse direction if out of bounds
		}

        // Update animation
        n.AnimData.running_time += dt
        if n.AnimData.running_time >= n.AnimData.update_time {
            n.AnimData.running_time = 0.0
            n.AnimData.current_frame = (n.AnimData.current_frame + 1) % n.AnimData.frame_count
            n.AnimData.frame_rec.x = f32(n.AnimData.current_frame) * n.AnimData.frame_rec.width
        }
    }

    return all_off_screen // Return true if all nebulae are off-screen
}

draw_end_screen :: proc() {
    rl.DrawText("Game Over!", rl.GetScreenWidth()/2 - 100, rl.GetScreenHeight()/2 - 50, 40, rl.RED)
    rl.DrawText("Press [ENTER] to Restart", rl.GetScreenWidth()/2 - 150, rl.GetScreenHeight()/2 + 10, 20, rl.WHITE)
}

draw_nebulae :: proc(nebulae: []Nebula) {
    for n in nebulae {
        rl.DrawTextureRec(
            n.texture,
            n.AnimData.frame_rec,
            n.position,
            rl.WHITE,
        )
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
	window := Window{"Dapper in Odin", 600, 350, 60, {.WINDOW_RESIZABLE}}
	rl.InitWindow(window.width, window.height, window.title)
	rl.SetWindowState(window.control_flags)
	rl.SetTargetFPS(window.fps)

	// Initialize the game
	game := Game{
		player = initialize_player("assets/scarfy.png", 1_000.0, -700.0),
		background = initialize_parallax_layer("assets/far-buildings.png", 20.0),
		midground = initialize_parallax_layer("assets/back-buildings.png", 40.0),
		foreground = initialize_parallax_layer("assets/foreground.png", 60.0),
		window = window,
		delta_time = 0.0,
	}

	nebula_texture := rl.LoadTexture("assets/12_nebula_spritesheet.png")
	nebulae := initialize_nebulae(nebula_texture, 10, 640.0, 300.0)

	defer close_game(&game)
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

			for nebula in nebulae {
				if collides(nebula.rect, game.player.rect) {
					running = false
				}
			}
			if update_nebulae(nebulae, rl.GetFrameTime(), game.window.width) {
				running = false 
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

			draw_nebulae(nebulae)
			// Draw player
			draw_player(game.player)

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
				nebulae = initialize_nebulae(nebula_texture, 10, 640.0, 450.0)
				running = true
			}
		}
	}
}
