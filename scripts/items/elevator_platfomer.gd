extends StaticBody2D

@export var height_limit: int = 200           # How high it should go (in pixels)
@export var elevator_id: String = "elevator:A"
@export var speed: float = 120.0              # Pixels per second
@export var wait_time: float = 1.5            # Seconds to wait at top and bottom

var is_activated: bool = false
var is_moving: bool = false
var moving_up: bool = true                    # True = going up, False = going down

var start_y: float = 0.0
var target_y: float = 0.0

@onready var wait_timer: Timer = Timer.new()

func _ready() -> void:
	start_y = global_position.y
	# Target position when going UP (remember: smaller Y = higher on screen)
	target_y = start_y - height_limit
	
	# Setup timer
	wait_timer.one_shot = true
	wait_timer.timeout.connect(_on_wait_timer_timeout)
	add_child(wait_timer)

func _process(delta: float) -> void:
	if not is_activated or not is_moving:
		return
	
	var move_speed = speed * delta
	
	if moving_up:
		global_position.y -= move_speed          # Move UP
		if global_position.y <= target_y:        # Reached top
			global_position.y = target_y
			stop_and_wait()
	else:
		global_position.y += move_speed          # Move DOWN
		if global_position.y >= start_y:         # Reached bottom
			global_position.y = start_y
			stop_and_wait()

# Called when the receiver is activated
func register_receiver_activation_event(id: String) -> void:
	if id != elevator_id:
		return
	
	if not is_activated:
		is_activated = true
		start_elevator()                       # Start the movement cycle

func start_elevator() -> void:
	is_moving = true
	moving_up = true                           # Always start by going UP

func stop_and_wait() -> void:
	is_moving = false
	wait_timer.start(wait_time)

func _on_wait_timer_timeout() -> void:
	# Switch direction
	moving_up = not moving_up
	is_moving = true
