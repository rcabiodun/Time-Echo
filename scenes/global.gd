extends Node

var score = 0
var player_name = "Hero"
var is_recording = false

var music_bus_index : int

func _ready() -> void:
	music_bus_index = AudioServer.get_bus_index("Music")
	$AudioStreamPlayer.play()

func _process(delta: float) -> void:
	if is_recording:
		AudioServer.set_bus_mute(music_bus_index, true)
	else:
		AudioServer.set_bus_mute(music_bus_index, false)
