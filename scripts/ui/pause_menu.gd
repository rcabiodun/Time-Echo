extends CanvasLayer

signal resume_pressed
signal restart_pressed
signal settings_pressed
signal main_menu_pressed

var is_paused := false

@onready var card = $Card

func _ready():
	visible = false
	$Card/Layout/ResumeButton.pressed.connect(_on_resume)
	
	$Card/Layout/SettingsButton.pressed.connect(_on_settings)
	$Card/Layout/MainMenuButton.pressed.connect(_on_main_menu)

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	visible = is_paused
	get_tree().paused = is_paused
	Global._showing_menu = is_paused
	
	if is_paused:
		Global._play_ui_sfx(Global.UISound.MENU_OPEN)

func _on_resume():
	print("resume has been pressed")
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	toggle_pause()

func _on_restart():
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	get_tree().paused = false
	Global._showing_menu = false
	visible = false
	get_tree().reload_current_scene()

func _on_settings():
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	var settings = preload("res://scenes/ui/settings_menu.tscn").instantiate()
	add_child(settings)
	settings.back_pressed.connect(_on_settings_closed.bind(settings))

func _on_settings_closed(settings: Node):
	settings.queue_free()

func _on_main_menu():
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	get_tree().paused = false
	Global._showing_menu = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
