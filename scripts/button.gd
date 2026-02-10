extends Area2D

# This signal tells the world:
# "A button linked to door_id has changed state"
signal button_state_changed(door_id: String, pressed: bool)

# The ID of the door this button controls
@export var door_id: String = "A"

# Tracks whether the button is currently being pressed
var is_pressed := false

func _ready():
	# Detect when a physics body enters or exits the button area
	pass
	#connect("body_entered", _on_body_entered)
	#connect("body_exited", _on_body_exited)
#


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("echo") and not is_pressed:
		print("Body entered; "+ body.name)
		is_pressed = true
		button_state_changed.emit( door_id, is_pressed)




func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("echo") and is_pressed:
		is_pressed = false
		button_state_changed.emit(door_id, is_pressed)
