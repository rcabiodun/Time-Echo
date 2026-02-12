extends Area2D

# This signal tells the world:
# "A button linked to door_id has changed state"
signal button_state_changed(door_id: String, pressed: bool)
# game_enums.gd
enum ALLOWEDACTIVATORS { PLAYER, ECHO }

# The ID of the door this button controls
@export var door_id: String = "A"
@export var allowed_activator:ALLOWEDACTIVATORS=ALLOWEDACTIVATORS.ECHO
# Tracks whether the button is currently being pressed
var is_pressed := false



func _on_body_entered(body: Node2D) -> void:
	#print("Body entered is; "+ body.name)
	if allowed_activator ==ALLOWEDACTIVATORS.ECHO:
		if body.is_in_group("echo") and not is_pressed:
			#print("Body entered; "+ body.name)
			is_pressed = true
			button_state_changed.emit( door_id, is_pressed)
	elif allowed_activator ==ALLOWEDACTIVATORS.PLAYER :
		if body.is_in_group("player") and not is_pressed:
			#print("Body entered; "+ body.name)
			is_pressed = true
			button_state_changed.emit( door_id, is_pressed)




func _on_body_exited(body: Node2D) -> void:
	if allowed_activator ==ALLOWEDACTIVATORS.ECHO:
		if body.is_in_group("echo") and is_pressed:
			is_pressed = false
			button_state_changed.emit(door_id, is_pressed)
	elif  allowed_activator ==ALLOWEDACTIVATORS.PLAYER:
		if body.is_in_group("player") and is_pressed:
			is_pressed = false
			button_state_changed.emit(door_id, is_pressed)
		
