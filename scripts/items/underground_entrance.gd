extends Area2D

@export var extra_margin: int = 100     # ← How many extra pixels below the player you want to see
@export var transition_duration: float = 0.8

var tween: Tween
var current_camera: Camera2D = null
var normal_limit_bottom: int = 0        # Will be saved automatically when player first enters

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	print(body.name)
	if not (body.is_in_group("player") or body.name == "Player"):
		return
	
	current_camera = body.get_node_or_null("Camera2D")
	if not current_camera:
		return
	
	# First time entering → save the original normal limit
	if normal_limit_bottom == 0:
		normal_limit_bottom = current_camera.limit_bottom
	
	enter_underground(body)

func _on_body_exited(body: Node2D) -> void:
	if (body.is_in_group("player") or body.name == "Player") and current_camera:
		exit_underground()

func enter_underground(player: Node2D) -> void:
	if not current_camera:
		return
	
	# Dynamically calculate new limit based on player's current Y position
	var new_limit: int = int(player.global_position.y) + extra_margin
	
	# Only expand if it's actually bigger than current limit
	if new_limit > current_camera.limit_bottom:
		kill_tween()
		tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(current_camera, "limit_bottom", new_limit, transition_duration)

func exit_underground() -> void:
	if not current_camera or normal_limit_bottom == 0:
		return
	
	kill_tween()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(current_camera, "limit_bottom", normal_limit_bottom, transition_duration)

func kill_tween() -> void:
	if tween and tween.is_running():
		tween.kill()
