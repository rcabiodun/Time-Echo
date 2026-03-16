extends RigidBody2D

# Exported variables – tweak in the inspector
@export var fall_delay : float = 1.0          # time before platform falls
@export var hide_delay : float = 0.5          # time after falling before platform disappears
@export var respawn_delay : float = 3.0       # time before platform reappears

# References to child nodes
@onready var top_detector : Area2D = $TopDetector
@onready var fall_timer : Timer = $FallTimer
@onready var hide_timer : Timer = $HideTimer
#@onready var respawn_timer : Timer = $RespawnTimer
@onready var respawn_timer: Timer = $RespawnTimer

# Store the original position for respawning
var original_position : Vector2

# State flags
var is_active : bool = true                    # true when platform is ready to detect player

func _ready():
	original_position = global_position
	# Set timers' wait times
	fall_timer.wait_time = fall_delay
	hide_timer.wait_time = hide_delay
	respawn_timer.wait_time = respawn_delay
	
	# Connect signals
	top_detector.body_entered.connect(_on_top_detector_body_entered)
	top_detector.body_exited.connect(_on_top_detector_body_exited)
	fall_timer.timeout.connect(_on_fall_timer_timeout)
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)

# Called when a body enters the top detector
func _on_top_detector_body_entered(body: Node) -> void:
	# Check if the body is the player (using the "player" group)
	if body.is_in_group("player") and is_active:
		print("Player is on the platform!!")
		# Start the fall timer if not already running
		if not fall_timer.is_stopped():
			fall_timer.stop()
		fall_timer.start()

# Called when a body exits the top detector
func _on_top_detector_body_exited(body: Node) -> void:
	if body.is_in_group("player") and is_active:
		# Stop the fall timer if the player leaves early
		fall_timer.stop()

# Fall timer expired – start the falling sequence
func _on_fall_timer_timeout():
	# Prevent further detection while falling
	is_active = false
	top_detector.monitoring = false
	
	# Optional: add a little visual feedback (e.g., change color or shake)
	# Here we simply unfreeze the platform so it falls
	freeze = false          # disable freeze → platform becomes dynamic and falls
	linear_velocity = Vector2.ZERO   # ensure no leftover velocity
	
	# Start the hide timer (platform will vanish after a short while)
	hide_timer.start()

# Hide timer expired – make the platform invisible and prepare for respawn
func _on_hide_timer_timeout():
	# Hide the platform
	visible = false
	
	# Freeze it again to stop any physics movement
	freeze = true
	
	# Reset velocity and rotation
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	
	# Start the respawn timer
	respawn_timer.start()

# Respawn timer expired – bring the platform back
func _on_respawn_timer_timeout():
	# Restore original position and rotation
	global_position = original_position
	rotation = 0
	
	# Make it visible again
	visible = true
	
	# Re‑enable detection
	is_active = true
	top_detector.monitoring = true
	
	# (Optional) reset any other state like modulation
