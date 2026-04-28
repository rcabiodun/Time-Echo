extends Control

func _ready():
	$Card/Layout/PlayButton.pressed.connect(_on_play)
	$Card/Layout/LevelSelectButton.pressed.connect(_on_level_select)
	$Card/Layout/HowToPlayButton.pressed.connect(_on_how_to_play)
	$Card/Layout/SettingsButton.pressed.connect(_on_settings)
	$Card/Layout/QuitButton.pressed.connect(_on_quit)

func _on_play():
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	Global.selected_level = -1
	Global.replay_mode = false
	get_tree().change_scene_to_file("res://scenes/levels/level_proc.tscn")

func _on_level_select():
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_how_to_play():
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	get_tree().change_scene_to_file("res://scenes/ui/how_to_play.tscn")

func _on_settings():
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	var settings = preload("res://scenes/ui/settings_menu.tscn").instantiate()
	add_child(settings)
	settings.back_pressed.connect(_on_settings_closed.bind(settings))

func _on_settings_closed(settings: Node):
	settings.queue_free()

func _on_quit():
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	get_tree().quit()
