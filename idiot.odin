package main

import "core:fmt"
import "core:math/rand"

import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import mix "vendor:sdl2/mixer"

WIN_WIDTH: i32 = 200
WIN_HEIGHT: i32 = 200
FPS: u32 = 30
BG_RECT := sdl.Rect{0, 0, WIN_WIDTH, WIN_HEIGHT}

SCREEN_WIDTH: i32 = 0
SCREEN_HEIGHT: i32 = 0

Window :: struct {
	win:           ^sdl.Window,
	ren:           ^sdl.Renderer,
	image:         ^sdl.Surface,
	image_texture: ^sdl.Texture,
	win_speed:     i32,
	posx:          i32,
	posy:          i32,
	dx:            i32,
	dy:            i32,
}

State :: struct {
	windows:     [dynamic]Window,
	music:       ^mix.Music,
	image:       ^sdl.Surface,
	next_time:   u32,
	timer:       u32,
	should_exit: bool,
	win_speed:   i32,
}

blink_image :: proc(image: ^sdl.Surface) {
	sdl.LockSurface(image)
	defer sdl.UnlockSurface(image)

	pixels := ([^]u32)(image.pixels)[:200 * 200]

	for _, i in pixels {
		pixel := pixels[i]
		defer pixels[i] = pixel

		red := u8((pixel >> 16)) & 0xFF
		green := u8((pixel >> 8)) & 0xFF
		blue := u8(pixel) & 0xFF

		red = 255 - red
		green = 255 - green
		blue = 255 - blue

		pixel = 0xff << 24 | u32(red) << 16 | u32(green) << 8 | u32(blue)
	}

	image.pixels = raw_data(pixels)
}

window_new :: proc(image: ^sdl.Surface, win_speed: i32) -> (win: Window) {
	sdl_win_ren_create_error := sdl.CreateWindowAndRenderer(
		WIN_WIDTH,
		WIN_HEIGHT,
		sdl.WINDOW_SHOWN,
		&win.win,
		&win.ren,
	)
	assert(sdl_win_ren_create_error == 0, sdl.GetErrorString())

	sdl.SetWindowTitle(win.win, "you are an idiot")
	sdl.GetWindowPosition(win.win, &win.posx, &win.posy)

	// surfaces setup
	win.image = sdl.ConvertSurface(image, image.format, 0)
	assert(win.image != nil, sdl.GetErrorString())
	win.image_texture = sdl.CreateTextureFromSurface(win.ren, win.image)
	assert(win.image_texture != nil, sdl.GetErrorString())

	// calculate fuzz
	xfuzz := rand.int31_max(SCREEN_WIDTH / 100) + 1
	yfuzz := rand.int31_max(SCREEN_HEIGHT / 100) + 1

	// set initial speeds
	win.win_speed = win_speed
	win.dx = win.win_speed
	win.dy = win.win_speed

	// randomize directions and add fuzz
	num := rand.uint32()
	if num % 4 == 1 {
		win.dx *= -1
		win.posx -= xfuzz
		win.posy += yfuzz
	} else if num % 4 == 2 {
		win.dx *= -1
		win.dy *= -1
		win.posx -= xfuzz
		win.posy -= yfuzz
	} else if num % 2 == 3 {
		win.dy *= -1
		win.posx += xfuzz
		win.posy -= yfuzz
	} else {
		win.posx += xfuzz
		win.posy += yfuzz
	}

	return win
}

window_update_position :: proc(win: ^Window) {
	win.posx += win.dx
	win.posy += win.dy

	if win.posx + WIN_WIDTH > SCREEN_WIDTH {
		win.posx = SCREEN_WIDTH - WIN_WIDTH
		win.dx = -1 * win.win_speed
	} else if win.posx < 0 {
		win.dx = win.win_speed
	}

	if win.posy < 0 {
		win.dy = win.win_speed
	} else if win.posy + WIN_HEIGHT > SCREEN_HEIGHT {
		win.posy = SCREEN_HEIGHT - WIN_HEIGHT
		win.dy = -1 * win.win_speed
	}

	sdl.SetWindowPosition(win.win, win.posx, win.posy)
}


window_loop :: proc(win: ^Window, timer: u32) {
	if timer % (FPS / 2) == 0 {
		blink_image(win.image)
		sdl.UpdateTexture(win.image_texture, nil, win.image.pixels, win.image.pitch)
		sdl.RenderClear(win.ren)
		sdl.RenderCopy(win.ren, win.image_texture, nil, nil)
		sdl.RenderPresent(win.ren)
	}

	window_update_position(win)
}

window_deinit :: proc(win: ^Window) {
	sdl.DestroyTexture(win.image_texture)
	sdl.DestroyRenderer(win.ren)
	sdl.DestroyWindow(win.win)
}

app_init :: proc(state: ^State) {
	sdl_init_err := sdl.Init(sdl.INIT_EVERYTHING)
	assert(sdl_init_err == 0, sdl.GetErrorString())
	mix_init_err := mix.Init(mix.INIT_MP3)

	// nice and calming music
	mix.OpenAudio(44100, sdl.AUDIO_S16, 1, 4096)
	state.music = mix.LoadMUS("./sound.mp3")
	mix.PlayMusic(state.music, -1)

	// amazing imag™
	state.image = img.Load("./image.png")
	assert(state.image != nil, sdl.GetErrorString())

	state.next_time = sdl.GetTicks() + FPS
	state.win_speed = 3

	// create screen width and height
	dm: sdl.DisplayMode
	sdl.GetCurrentDisplayMode(0, &dm)

	SCREEN_WIDTH = dm.w
	SCREEN_HEIGHT = dm.h

	// append window to the array
	state.windows = make([dynamic]Window)
	newwin := window_new(state.image, state.win_speed)
	append(&state.windows, newwin)


	fmt.printf("w:%d, h:%d", SCREEN_WIDTH, SCREEN_HEIGHT)
}

app_deinit :: proc(state: ^State) {
	for _, i in state.windows {
		window_deinit(&state.windows[i])
	}
	delete(state.windows)

	sdl.FreeSurface(state.image)
	mix.FreeMusic(state.music)
	mix.CloseAudio()
	sdl.Quit()
}

app_get_remaining_time :: proc(state: ^State) -> u32 {
	now := sdl.GetTicks()

	if state.next_time <= now {
		return 0
	} else {
		return state.next_time - now
	}
}

app_spawn_new_windows :: proc(state: ^State) {
	for i in 1 ..= 6 {
		append(&state.windows, window_new(state.image, state.win_speed))
		state.win_speed += 2
	}
}

app_loop :: proc(state: ^State) {
	evt: sdl.Event

	for _, i in state.windows {
		window_loop(&state.windows[i], state.timer)
	}

	for sdl.PollEvent(&evt) {
		if evt.type == sdl.EventType.QUIT {
			app_spawn_new_windows(state)
		}

		if evt.type == sdl.EventType.KEYDOWN {
			app_spawn_new_windows(state)
		}
	}

	sdl.Delay(app_get_remaining_time(state))
	state.next_time += FPS
	state.timer += 1
}

main :: proc() {
	state := State{}

	app_init(&state)
	defer app_deinit(&state)

	for !state.should_exit {app_loop(&state)}
}
