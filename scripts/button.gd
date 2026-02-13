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
@onready var rune_requirement = $RuneRequirement


var _required_runes: Array[String] = []

@export var required_runes: Array[String]:
	set(value):
		_required_runes = value
		# Only propagate if the node is valid
		if is_instance_valid(rune_requirement):
			rune_requirement.required_runes = value
	get:
		# If RuneRequirement exists and has a value, return that; else return backing
		if is_instance_valid(rune_requirement) and rune_requirement.required_runes.size() > 0:
			return rune_requirement.required_runes
		return _required_runes


func _ready():
	# Propagate inspector values manually at runtime to ensure RuneRequirement has them
	rune_requirement.required_runes = _required_runes

	print("Button backing _required_runes:", _required_runes)
	print("Button property required_runes:", required_runes)
	print("Button required_runes:", rune_requirement.required_runes)


func _on_body_entered(body: Node2D) -> void:
	#print("Body entered is; "+ body.name)
	if allowed_activator ==ALLOWEDACTIVATORS.ECHO:
		if body.is_in_group("echo") and not is_pressed and rune_requirement.are_required_runes_active_for_echo(body.echo_id):
			#print("Body entered; "+ body.name)
			is_pressed = true
			button_state_changed.emit( door_id, is_pressed,body.echo_id)
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
		
