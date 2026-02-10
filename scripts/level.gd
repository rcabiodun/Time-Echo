extends Node2D

# Preload Echo scene
@onready var EchoScene = preload("res://scenes/echo.tscn")

func _ready():
	# Connect every button in the level to the level manager
	for button in get_tree().get_nodes_in_group("buttons"):
		button.connect("button_state_changed", _on_button_state_changed)

# When ANY button changes, notify all doors
func _on_button_state_changed(door_id: String, pressed: bool):
	for door in get_tree().get_nodes_in_group("doors"):
		door.register_button_event(door_id, pressed)

# Called when player finishes recording
func _on_player_create_echo(frames: Array) -> void:
	# 🔄 WORLD RESET HAPPENS HERE
	for obj in get_tree().get_nodes_in_group("resettable"):
		obj.reset_if_needed()
	# Remove old echo (V1 rule: only ONE echo exists)
	#for child in $Echoes.get_children():
		#child.queue_free()
	
	# Create new echo
	var echo = EchoScene.instantiate()
	$Echoes.add_child(echo)

	# Start playback using recorded timeline
	echo.start_playback(frames)
