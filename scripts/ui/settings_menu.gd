extends CanvasLayer

signal back_pressed

@onready var music_slider: HSlider = $Card/Layout/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Card/Layout/SFXRow/SFXSlider
#@onready var lighting_checkbox: CheckBox = $Card/Layout/LightingRow/LightingCheckBox
@onready var lighting_checkbox: CheckButton = $Card/Layout/LightingRow/LightingCheckBox

var music_bus_index: int
var sfx_bus_index: int
var config: ConfigFile

func _ready():
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	config = ConfigFile.new()
	load_settings()
	
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	lighting_checkbox.toggled.connect(_on_lighting_toggled)
	$Card/Layout/BackButton.pressed.connect(_on_back)

#func load_settings():
	#if config.load("user://settings.cfg") == OK:
		#music_slider.value = config.get_value("audio", "music_volume", 0.0)
		#sfx_slider.value = config.get_value("audio", "sfx_volume", 0.0)
		#Global.environment_lighting_enabled = config.get_value("graphics", "environment_lighting", true)
	#else:
		## First run – get current bus volumes (default 0.0)
		#music_slider.value = AudioServer.get_bus_volume_db(music_bus_index)
		#sfx_slider.value = AudioServer.get_bus_volume_db(sfx_bus_index)
		#Global.environment_lighting_enabled = true
	#
	#lighting_checkbox.button_pressed = Global.environment_lighting_enabled
	## Apply immediately (in case we're in a level)
	#Global.apply_lighting_setting()

func load_settings():
	if config.load("user://settings.cfg") == OK:
		music_slider.value = config.get_value("audio", "music_volume", 0.0)
		sfx_slider.value = config.get_value("audio", "sfx_volume", 0.0)
		# Don't set Global.environment_lighting_enabled here – it's already correct
	else:
		music_slider.value = AudioServer.get_bus_volume_db(music_bus_index)
		sfx_slider.value = AudioServer.get_bus_volume_db(sfx_bus_index)
		# Defaults remain

	lighting_checkbox.button_pressed = Global.environment_lighting_enabled
	Global.apply_lighting_setting()   # still useful if opened mid-game
func _on_music_changed(value: float):
	AudioServer.set_bus_volume_db(music_bus_index, value)
	config.set_value("audio", "music_volume", value)
	config.save("user://settings.cfg")

func _on_sfx_changed(value: float):
	AudioServer.set_bus_volume_db(sfx_bus_index, value)
	config.set_value("audio", "sfx_volume", value)
	config.save("user://settings.cfg")

func _on_lighting_toggled(button_pressed: bool):
	Global.environment_lighting_enabled = button_pressed
	config.set_value("graphics", "environment_lighting", button_pressed)
	config.save("user://settings.cfg")
	Global.apply_lighting_setting()

func _on_back():
	emit_signal("back_pressed")
	queue_free()
