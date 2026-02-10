extends CharacterBody2D

var start_position: Vector2

# Carry system
var being_carried := false
var carrier: Node2D = null

# Gravity
const GRAVITY := 900.0

func _ready():
	start_position = global_position
	#add_to_group("carryable")
	#add_to_group("resettable")

func _physics_process(delta):
	# Only fall when not being carried
	if not being_carried:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		else:
			velocity.y = 0

		move_and_slide()

# Called by player
func pick_up(player: Node2D):
	being_carried = true
	carrier = player
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false) # Temporarily disable world collision

func drop():
	being_carried = false
	carrier = null
	set_collision_layer_value(1, true)
	print("dropped") # Re-enable world collision

func follow_target(target_pos: Vector2):
	if being_carried:
		global_position = global_position.lerp(target_pos, 0.25)

func reset_if_needed():
	if not being_carried:
		global_position = start_position
		velocity = Vector2.ZERO
