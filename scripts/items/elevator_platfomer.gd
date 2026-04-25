extends StaticBody2D

enum MovementDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@export var direction: MovementDirection = MovementDirection.UP
@export var travel_distance: int = 200           # How far it should move (in pixels)
@export var elevator_id: String = "elevator:A"
@export var speed: float = 120.0                 # Pixels per second
@export var wait_time: float = 1.5               # Seconds to wait at ends

var is_activated: bool = false
var is_moving: bool = false
var moving_forward: bool = true                  # True = moving to target, False = returning to start

var start_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

# Store characters currently on the elevator (players and echoes)
var characters_on_elevator: Array = []

@onready var wait_timer: Timer = Timer.new()

func _ready() -> void:
	#is_activated=true
	#start_movement()
	start_position = global_position
	
	# Calculate target position based on direction
	match direction:
		MovementDirection.UP:
			target_position = start_position + Vector2(0, -travel_distance)
		MovementDirection.DOWN:
			target_position = start_position + Vector2(0, travel_distance)
		MovementDirection.LEFT:
			target_position = start_position + Vector2(-travel_distance, 0)
		MovementDirection.RIGHT:
			target_position = start_position + Vector2(travel_distance, 0)
	
	# Setup timer
	wait_timer.one_shot = true
	wait_timer.timeout.connect(_on_wait_timer_timeout)
	add_child(wait_timer)

func _process(delta: float) -> void:
	if not is_activated or not is_moving:
		return
	
	var move_distance = speed * delta
	var movement = Vector2.ZERO
	
	if moving_forward:
		# Move towards target position
		movement = target_position - global_position
		if movement.length() <= move_distance:
			# Reached target
			global_position = target_position
			stop_and_wait()
		else:
			global_position += movement.normalized() * move_distance
	else:
		# Move back to start position
		movement = start_position - global_position
		if movement.length() <= move_distance:
			# Reached start
			global_position = start_position
			stop_and_wait()
		else:
			global_position += movement.normalized() * move_distance
	
	# Move any characters standing on the elevator
	for character in characters_on_elevator:
		if is_instance_valid(character):
			character.global_position += movement.normalized() * move_distance

# Handle collision (entering elevator)
func _on_player_detector_body_entered(body: Node2D) -> void:
	# Check if it's the player OR an echo
	if body.is_in_group("player") or body.is_in_group("echo") or body.name == "Player" or body.name.begins_with("Echo"):
		if not body in characters_on_elevator:
			characters_on_elevator.append(body)
			print("Character entered elevator: ", body.name, ". Total characters: ", characters_on_elevator.size())

# Handle collision (exiting elevator)
func _on_player_detector_body_exited(body: Node2D) -> void:
	if body in characters_on_elevator:
		characters_on_elevator.erase(body)
		print("Character exited elevator: ", body.name, ". Total characters: ", characters_on_elevator.size())

# Called when the receiver is activated
func register_receiver_activation_event(id: String) -> void:
	if id != elevator_id:
		return
	
	if not is_activated:
		is_activated = true
		start_movement()

func start_movement() -> void:
	is_moving = true
	moving_forward = true                        # Always start by moving to target

func stop_and_wait() -> void:
	is_moving = false
	wait_timer.start(wait_time)

func _on_wait_timer_timeout() -> void:
	# Switch direction
	moving_forward = not moving_forward
	is_moving = true
