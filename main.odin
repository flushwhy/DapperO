package DapperO

import rl "vendor:raylib"


Window :: struct {
	title:         cstring,
	width:         i32,
	height:        i32,
	fps:           i32,
	control_flags: rl.ConfigFlags,
}

main :: proc() {
	window := Window{"Dapper in Odin", 800, 450, 60, rl.ConfigFlags{.WINDOW_RESIZABLE}}

	rl.InitWindow(window.width, window.height, window.title)
	rl.SetWindowState(window.control_flags)
	rl.SetTargetFPS(window.fps)

	for !rl.WindowShouldClose() {

		if rl.IsWindowResized() {
			window.width = rl.GetScreenWidth()
			window.height = rl.GetScreenHeight()

			//cell.width = f32(window.width) / f32(world.width)
			//cell.height = f32(window.height) / f32(world.height)
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		rl.EndDrawing()
	}
}
