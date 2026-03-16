extends Node2D

@onready var canvas_modulate: CanvasModulate = $"../CanvasModulate"
var canvas_tween : Tween

# ✅ Distortion Shader
@onready var distortion_rect = $"../CanvasLayer/ColorRect"
var distortion_tween : Tween
var was_recording := false

# Preload Echo scene
@onready var EchoScene = preload("res://scenes/characters/echo.tscn")
var next_echo_id: int = 1


func _ready():
	# Connect every button in the level to the level manager
	for button in get_tree().get_nodes_in_group("buttons"):
		button.connect("button_state_changed", _on_button_state_changed)


# When ANY button changes, notify all doors
func _on_button_state_changed(door_id: String, pressed: bool, echo_id: int = 0):
	for door in get_tree().get_nodes_in_group("doors"):
		door.register_button_event(door_id, pressed, echo_id)


# Called every frame
func _process(delta):
	# Handle distortion activation only when state changes
	if Global.is_recording != was_recording:
		was_recording = Global.is_recording
		
		if was_recording:
			activate_distortion()
		else:
			deactivate_distortion()

	# Keep your existing darken effect
	if Global.is_recording:
		darken_scene()
	else:
		restore_scene()


# =========================
# 🎨 Darken Scene
# =========================
func darken_scene():
	if canvas_tween:
		canvas_tween.kill()
	
	canvas_tween = create_tween()
	canvas_tween.tween_property(
		canvas_modulate,
		"color",
		Color(0.4, 0.4, 0.5, 1),
		0.8
	)


func restore_scene():
	if canvas_tween:
		canvas_tween.kill()
	
	canvas_tween = create_tween()
	canvas_tween.tween_property(
		canvas_modulate,
		"color",
		Color(1, 1, 1, 1),
		0.8
	)


# =========================
# 🌊 Distortion Animation
# =========================
func activate_distortion():
	if distortion_tween:
		distortion_tween.kill()
	
	distortion_tween = create_tween()
	distortion_tween.tween_property(
		distortion_rect.material,
		"shader_parameter/strength",
		0.6,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func deactivate_distortion():
	if distortion_tween:
		distortion_tween.kill()
	
	distortion_tween = create_tween()
	distortion_tween.tween_property(
		distortion_rect.material,
		"shader_parameter/strength",
		0.0,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# =========================
# 👻 Echo Creation
# =========================
func _on_player_create_echo(frames: Array) -> void:

	var active_echo_ids: Array[int] = []
	#for echo in $Echoes.get_children():
	for echo in $"../Echoes".get_children():
		if echo.get("echo_id") != null:
			active_echo_ids.append(echo.echo_id)

	for obj in get_tree().get_nodes_in_group("resettable"):
		obj.reset_if_needed(active_echo_ids)

	for rune in get_tree().get_nodes_in_group("runes"):
		rune.reset_rune_if_needed(active_echo_ids)

	var echo = preload("res://scenes/characters/echo.tscn").instantiate()
	print("")
	$"../Echoes".add_child(echo)

	echo.set_echo_id(next_echo_id)
	next_echo_id += 1

	echo.start_playback(frames)
