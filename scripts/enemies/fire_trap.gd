extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var activation_timer: Timer = $ActivationTimer
@onready var fire_burst: AudioStreamPlayer2D = $FireBurst

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start the timer when the scene loads
	activation_timer.wait_time = 3.0  # Adjust this value to set cooldown duration
	activation_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_hit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()

func _on_activation_timer_timeout() -> void:
	fire_burst.play()
	# Play the activate animation
	
	animation_player.play("activate")
	
	# Restart the timer for the next activation
	activation_timer.start()
