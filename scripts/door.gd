extends StaticBody2D

# The ID this door listens for
@export var door_id: String = "A"

# How many buttons with this ID must be pressed
@export var required_buttons: int = 1

# Tracks how many linked buttons are currently pressed
var pressed_count := 0

# References to door visuals and collision
@onready var collision = $CollisionShape2D
@onready var sprite = $Sprite2D



# Called by the level manager whenever ANY button changes state
func register_button_event(id: String, pressed: bool):
	# Ignore signals meant for other doors
	if id != door_id:
		return

	# Update how many buttons are currently pressed
	if pressed:
		pressed_count += 1
	else:
		pressed_count -= 1

	# Prevent negative values or overflow
	pressed_count = clamp(pressed_count, 0, required_buttons)

	# Open only if enough buttons are pressed
	if pressed_count >= required_buttons:
		open()
	else:
		close()
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
