extends StaticBody2D

# The ID this door listens for
@export var door_id: String = "A"

# How many buttons with this ID must be pressed
@export var required_buttons: int = 1

var current_button_echo_id: int = -1

#@onready var rune_requirement = $RuneRequirement

# Backing variable
  
#@onready var rune_requirement = $RuneRequirement



# Tracks how many linked buttons are currently pressed
var pressed_count := 0

# References to door visuals and collision
@onready var collision = $CollisionShape2D
@onready var sprite = $Sprite2D
@onready var rune_requirement = $RuneRequirement


#var _required_runes: Array[String] = []
#
#@export var required_runes: Array[String]:
	#set(value):
		#_required_runes = value
		## Only propagate if the node is valid
		#if is_instance_valid(rune_requirement):
			#rune_requirement.required_runes = value
	#get:
		## If RuneRequirement exists and has a value, return that; else return backing
		#if is_instance_valid(rune_requirement) and rune_requirement.required_runes.size() > 0:
			#return rune_requirement.required_runes
		#return _required_runes

#
#func _ready():
	## Propagate inspector values manually at runtime to ensure RuneRequirement has them
	#rune_requirement.required_runes = _required_runes
#
	#print("Door backing _required_runes:", _required_runes)
	#print("Door property required_runes:", required_runes)
	#print("RuneRequirement required_runes:", rune_requirement.required_runes)

# Called by the level manager whenever ANY button changes state
func register_button_event(id: String, pressed: bool,echo_id:int=0):
	# Ignore signals meant for other doors
	if id != door_id:
		return

	# Update how many buttons are currently pressed
	if pressed:
		pressed_count += 1
		current_button_echo_id=echo_id
	else:
		pressed_count -= 1
		if pressed_count == 0:
			current_button_echo_id=-1

	# Prevent negative values or overflow
	pressed_count = clamp(pressed_count, 0, required_buttons)

	# Open only if enough buttons are pressed
	if pressed_count >= required_buttons:
		open()
	else:
		close()
		
#func _check_runes_now(echo_id:int=-1):
	#if pressed_count >= required_buttons and rune_requirement.are_required_runes_active_for_echo(echo_id):
		#open()
	#else:
		#close()

func open():
	print("opening door")

	# Turn OFF door layer so player can't collide
	set_collision_layer_value(4, false)
	sprite.modulate.a = 0.3

func close():
	print("closing door")

	# Turn door collision back ON
	set_collision_layer_value(4, true)
	sprite.modulate.a = 1.0
