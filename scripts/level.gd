extends Node2D

# Preload Echo scene
@onready var EchoScene = preload("res://scenes/echo.tscn")
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

func _on_player_create_echo(frames: Array) -> void:

	var active_echo_ids: Array[int] = []
	for echo in $Echoes.get_children():
		active_echo_ids.append(echo.echo_id)
	
	for obj in get_tree().get_nodes_in_group("resettable"):
		obj.reset_if_needed(active_echo_ids)
	for rune in get_tree().get_nodes_in_group("runes"):
		rune.reset_rune_if_needed(active_echo_ids)

	var echo = preload("res://scenes/echo.tscn").instantiate()
	$Echoes.add_child(echo)

	echo.set_echo_id(next_echo_id)
	next_echo_id += 1

	echo.start_playback(frames)
