extends Node

var score = 0
var player_name = "Hero"
var music_bus_index: int
#var player_around_interactable:bool=false
var interactable_count: int = 0
var player_around_interactable: bool = false
#var current_level_generated_rooms : Array[PackedScene] = []
signal recording_started
signal recording_stopped

var is_recording := false :
	set(value):
		is_recording = value
		AudioServer.set_bus_mute(music_bus_index, value)
		if value:
			recording_started.emit()
		else:
			recording_stopped.emit()

func _ready() -> void:
	music_bus_index = AudioServer.get_bus_index("Music")
	$AudioStreamPlayer.play()
