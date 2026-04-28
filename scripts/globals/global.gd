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
var _showing_menu:bool=false
var environment_lighting_enabled := true

@onready var button_select_audio: AudioStreamPlayer = $ButtonSelectAudio
@onready var menu_open_audio: AudioStreamPlayer = $MenuOpenAudio


enum UISound {
	BUTTON_SELECT,
	MENU_OPEN
}


# Global.gd (autoload)
var selected_level: int = -1     # -1 means use normal progression
var replay_mode: bool = false    # true when replaying a completed level
#When the Level Select screen loads a level, it will set these before changing scene.
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
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		environment_lighting_enabled = config.get_value("graphics", "environment_lighting", true)
	else:
		environment_lighting_enabled = true


func _play_ui_sfx(sound: UISound):
	match sound:
		UISound.BUTTON_SELECT:
			button_select_audio.play()
		UISound.MENU_OPEN:
			menu_open_audio.play()
			



#func apply_lighting_setting() -> void:
	#for light in get_tree().get_nodes_in_group("lights"):
		#if light is PointLight2D:
			#light.enabled = environment_lighting_enabled


func apply_lighting_setting() -> void:
	var lights = get_tree().get_nodes_in_group("lights")
	for light in lights:
		if light is PointLight2D:
			light.visible = environment_lighting_enabled
