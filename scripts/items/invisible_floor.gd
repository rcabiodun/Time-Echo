extends StaticBody2D

# The ID this floor listens for
@export var invisible_floor_id: String = "floor:A"

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

func _ready() -> void:
	close()


func register_button_event(id: String, pressed: bool,echo_id:int=0):
	# Ignore signals meant for other doors
	if id != invisible_floor_id:
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
		


func open():
	print("showing floor")
	# Turn door collision back ON
	set_collision_layer_value(4, true)
	sprite.modulate.a = 1.0

	

func close():
	print("not showing floor")



# Turn OFF door layer so player can't collide
	set_collision_layer_value(4, false)
	sprite.modulate.a = 0.3
