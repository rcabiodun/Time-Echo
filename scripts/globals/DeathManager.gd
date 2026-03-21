extends Node

var is_dead := false

func trigger_death_freeze_and_fade() -> void:

	if is_dead: return
	is_dead = true
	
	# 1. Short freeze frame
	var freeze_duration = 0.35
	var freeze_strength = 0.06   # ← tweak between 0.0–0.1
	
	Engine.time_scale = freeze_strength
	await get_tree().create_timer(freeze_duration, true, false, true).timeout
	Engine.time_scale = 1.0
	
	# 2. Quick fade (keep short!)
	var fade_duration = 0.22     # ← try 0.18–0.28
	var fade_rect = get_tree().get_first_node_in_group("fade_rect")
	
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, fade_duration)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_LINEAR)
		await tween.finished
	
	# 3. Restart
	get_tree().reload_current_scene()
	
	is_dead = false
	

func trigger_room_transition(load_callback: Callable) -> void:
	var fade_rect = get_tree().get_first_node_in_group("fade_rect")
	
	if fade_rect == null:
		push_error("No fade_rect found!")
		return
	
	var fade_duration = 0.22
	
	# =========================
	# 1️⃣ Fade OUT (to black)
	# =========================
	var tween_out = create_tween()
	tween_out.tween_property(fade_rect, "color:a", 1.0, fade_duration)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_LINEAR)
	
	await tween_out.finished

	# =========================
	# 2️⃣ Load new room
	# =========================
	await load_callback.call()

	# Small safety frame (ensures room fully ready)
	await get_tree().process_frame

	# =========================
	# 3️⃣ Fade IN (back to game)
	# =========================
	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, fade_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_LINEAR)
