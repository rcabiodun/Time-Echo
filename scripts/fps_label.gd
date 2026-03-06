extends Label

var fps_accumulator := 0.0
var frame_count := 0
var display_fps := 0

func _process(delta):
	fps_accumulator += delta
	frame_count += 1

	if fps_accumulator >= 0.5:
		display_fps = frame_count / fps_accumulator
		frame_count = 0
		fps_accumulator = 0.0

	text = "FPS: " + str(round(display_fps))
