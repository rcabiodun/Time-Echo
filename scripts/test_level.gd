extends Node2D
#@onready var canvas = 
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
var canvas_tween : Tween
# Preload Echo scene
@onready var EchoScene = preload("res://scenes/characters/echo.tscn")
var next_echo_id: int = 1

func _ready():
	# Connect every button in the level to the level manager
	for button in get_tree().get_nodes_in_group("buttons"):
		button.connect("button_state_changed", _on_button_state_changed)

# When ANY button changes, notify all doors
func _on_button_state_changed(door_id: String, pressed: bool,echo_id:int=0):
	for door in get_tree().get_nodes_in_group("doors"):
		door.register_button_event(door_id, pressed,echo_id)

# Called when player finishes recording
func _process(delta):
	if Global.is_recording:
		darken_scene()
	else:
		restore_scene()
func darken_scene():
	if canvas_tween:
		canvas_tween.kill()
	
	canvas_tween = create_tween()
	canvas_tween.tween_property(
		canvas_modulate,
		"color",
		Color(0.4, 0.4, 0.5, 1), # dark blue-gray tint
		0.8  # duration in seconds
	)

func restore_scene():
	if canvas_tween:
		canvas_tween.kill()
	
	canvas_tween = create_tween()
	canvas_tween.tween_property(
		canvas_modulate,
		"color",
		Color(1,1,1,1), # normal brightness
		0.8
	)
func _on_player_create_echo(frames: Array) -> void:

	var active_echo_ids: Array[int] = []
	for echo in $Echoes.get_children():
		active_echo_ids.append(echo.echo_id)
	
	for obj in get_tree().get_nodes_in_group("resettable"):
		obj.reset_if_needed(active_echo_ids)
	for rune in get_tree().get_nodes_in_group("runes"):
		rune.reset_rune_if_needed(active_echo_ids)

	var echo = preload("res://scenes/characters/echo.tscn").instantiate()
	$Echoes.add_child(echo)

	echo.set_echo_id(next_echo_id)
	next_echo_id += 1

	echo.start_playback(frames)

#darken it from the the level 
