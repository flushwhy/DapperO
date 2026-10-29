package DapperO

import rl "vendor:raylib"

// AABB collision detection
collides :: proc(a: rl.Rectangle, b: rl.Rectangle) -> bool {
	return(
		a.x < b.x + b.width &&
		a.x + a.width > b.x &&
		a.y < b.y + b.height &&
		a.y + a.height > b.y \
	)
}

initialize_player :: proc(filepath: cstring, gravity: f32, jump_strength: f32, window_height: i32) -> Player {
	texture := rl.LoadTexture(filepath)
	anim := Animation {
		frame_rec     = rl.Rectangle{0, 0, f32(texture.width) / 6, f32(texture.height)}, // Assuming 6 frames horizontally
		frame_count   = 6,
		current_frame = 0,
		update_time   = 1.0 / 12.0, // 12 FPS
		running_time  = 0.0,
	}

	return Player {
		texture = texture,
		position = rl.Vector2{100.0, f32(window_height) - f32(texture.height) - 60.0},
		velocity = rl.Vector2{0.0, 0.0},
		is_in_air = false,
		gravity = gravity,
		jump_strength = jump_strength,
		animation = anim,
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
	ground_y := f32(window_height) - player.animation.frame_rec.height - 60.0
	if player.position.y >= ground_y {
		player.position.y = ground_y
		player.velocity.y = 0
		player.is_in_air = false
	}

	// Jump
	if rl.IsKeyPressed(.SPACE) && !player.is_in_air {
		player.velocity.y = player.jump_strength
		player.is_in_air = true
	}

	if !player.is_in_air {
		player.animation.running_time += dt
		if player.animation.running_time >= player.animation.update_time {
			player.animation.running_time = 0.0
			player.animation.current_frame =
				(player.animation.current_frame + 1) % player.animation.frame_count
			player.animation.frame_rec.x =
				f32(player.animation.current_frame) * player.animation.frame_rec.width
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
		anim := Animation {
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
			animation = anim,
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
		player.animation.frame_rec,
		rl.Vector2{player.position.x, player.position.y},
		rl.WHITE,
	)
}

update_parallax_layer :: proc(layer: ^ParallaxLayer, dt: f32) {
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
		n.rect.width = n.animation.frame_rec.width
		n.rect.height = n.animation.frame_rec.height

		n.animation.running_time += dt
		for n.animation.running_time >= n.animation.update_time {
			n.animation.running_time -= n.animation.update_time
			n.animation.current_frame = (n.animation.current_frame + 1) % n.animation.frame_count
			n.animation.frame_rec.x = f32(n.animation.current_frame) * n.animation.frame_rec.width
		}
	}

	for i in 0 ..< len(nebulae) {
		n := &nebulae[i]
		if n.position.x + n.rect.width < 0 {
			rightmost := f32(rl.GetScreenWidth())
			for other in nebulae {
				other_right := other.position.x + other.rect.width
				if other_right >= 0 && other_right > rightmost {
					rightmost = other_right
				}
			}
			// Vary spacing deterministically; multiple recycled hazards remain evenly ordered.
			gap := 220.0 + f32((i * 73) % 140)
			n.position.x = rightmost + gap
			n.rect.x = n.position.x
		}
	}
}
