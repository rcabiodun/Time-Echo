extends CharacterBody2D

# ===============================
# 🎮 MOVEMENT CONSTANTS
# ===============================
const SPEED := 240.0

const WALK_SPEED_THRESHOLD := 170.0   # below this = walk
const RUN_SPEED_THRESHOLD  := 225.0  # above this = full run
var was_running := false
var is_stopping := false
const  DEFAULT_JUMP_VELOCITY := -355.0
var last_facing_direction: int = 1
var is_turning: bool = false
var turn_start_flip: bool = false

var JUMP_VELOCITY := DEFAULT_JUMP_VELOCITY
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D3
var was_on_floor := false
var landing := false
var is_in_activation := false
var was_carrying_last_frame := false
#var is_in_activation := false
#var landing := false


# ===============================
# ⏺ RECORDING SETTINGS
# ===============================
const MAX_RECORD_TIME := 15.0

# ===============================
# ✨ JUMP FEEL SETTINGS
# ===============================
@export var COYOTE_TIME := 0.12
@export var JUMP_BUFFER_TIME := 1

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

# ===============================
# 📦 TELEKINESIS CARRY SYSTEM
# ===============================
var carried_box: Node2D = null
@export var carry_distance := 52.0
@onready var pickup_area = $PickupArea #character is facing the right by default
@onready var record_sound:AudioStreamPlayer2D=$Sounds/RecordSound
@onready var jump_sound:AudioStreamPlayer2D=$Sounds/JumpSound
@onready var is_recording_sound: AudioStreamPlayer2D = $Sounds/IsRecordingSound
var interacted_this_frame := false
var facing_direction: float = 1.0 

# ===============================
# ⏺ RECORDING STATE
# ===============================
#var Global.is_recording: bool = false
var record_timer: float = 0.0
var recorded_frames: Array = []
#var sfx_bus_index : int
var sfx_bus_index : int
var was_recording := false
var glow_tween : Tween
var audio_tween : Tween
signal create_echo(frames)
@onready var recording_timer: Timer = $RecordingTimer
@onready var recording_progress_bar: ProgressBar = $RecordingProgressBar

var pulse_timer: float = 0.0
var is_pulsing: bool = false

# Store original stylebox colors for resetting
var original_fill_color: Color
var original_bg_color: Color


# ===============================
# ⏺ Camera STATE
# ===============================
@export var camera_zoom_default: float = 4.3
@export var camera_zoom_zoomed: float = 1.45
@export var zoom_animation_duration: float = 0.2

var current_zoom: float = 4.3
var is_zoomed_out: bool = true  # True = zoomed out (4.3), False = zoomed in (2.0)
var is_animating: bool = false

@onready var camera: Camera2D = $Camera2D  # Adjust path to your camera

func _ready() -> void:
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	update_collision_for_recording()
	current_zoom = camera_zoom_default
	camera.zoom = Vector2(current_zoom, current_zoom)
	


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("change_camera_zoom") and not is_animating:
		toggle_camera_zoom()
# ===============================
# 🔄 MAIN PHYSICS LOOP
# ===============================
func _physics_process(delta: float) -> void:
	#update_glow()
	
	play_recording_effects()
	#update_recording_label() 
	apply_gravity(delta)
	update_timers(delta)
	handle_jump()
	handle_movement(delta)
	handle_interact()
	handle_recording(delta)

	move_and_slide()
	var currently_on_floor = is_on_floor()

# Detect landing frame
	if !was_on_floor and currently_on_floor:
		landing = true

	was_on_floor = currently_on_floor

	update_animation()
	update_carried_box_position()


func update_recording_label():
	#func _process(delta):
	var new_text = "Recording!" if Global.is_recording else ""
	if $CanvasLayer/Label.text != new_text:
		$CanvasLayer/Label.text = new_text



func play_recording_effects():
	if Global.is_recording != was_recording:
		was_recording = Global.is_recording
		
		if was_recording:
			start_recording_effects()
		else:
			stop_recording_effects()
			




# ===============================
# 🌍 GRAVITY
# ===============================
func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

# ===============================
# ⏱ COYOTE + BUFFER TIMERS
# ===============================
func update_timers(delta):
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		#$AudioStreamPlayer2D.play()
		jump_sound.play()
		jump_buffer_timer = JUMP_BUFFER_TIME
		
	else:
		jump_buffer_timer -= delta

# ===============================
# 🦘 JUMP
# ===============================
func handle_jump():
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

# ===============================
# 🏃 MOVEMENT
# ===============================
func handle_movement(delta):
	var direction := Input.get_axis("left", "right")

	if direction != 0:
		facing_direction = direction  # Remember last move direction
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 4 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 6 * delta)
		
# ===============================
# ✋ INTERACT (PICK UP / DROP BOX)
# ===============================
func handle_interact():
	interacted_this_frame = false  # Reset each frame
	if Input.is_action_just_pressed("interact"):
		interacted_this_frame = true

		print("Pressing interact button")
		# Drop if already carrying
		if carried_box:
			JUMP_VELOCITY=DEFAULT_JUMP_VELOCITY
			
			print("player dropping box")
			carried_box.drop()
			carried_box = null
			
			return

		# Try picking up nearby carryable object
		for body in pickup_area.get_overlapping_bodies():
			var box = body# StaticBody → Box root
			
			if box and box.is_in_group("carryable"):
				JUMP_VELOCITY=-300
				carried_box = box
				box.pick_up(self)
				break
			
			if body and body.is_in_group("redirect_platform"):
				#body.begin_interaction(self)
				#body.rotate_platform()
				#body.end_interaction()
				print("trying to rotate plaform") 
				body.interact(self)
			if body and body.is_in_group("projectile"):
				body.launch(facing_direction)


# Move the carried box every frame
func update_carried_box_position():
	if carried_box:
		#var dir:float = sign(velocity.x)
		var dir: float = facing_direction

		if dir == 0:
			dir = 1  # Default to right if standing still

		var target_pos:Vector2 = global_position + Vector2(dir * carry_distance, -12)
		carried_box.follow_target(target_pos)

# ===============================
# ⏺ RECORDING SYSTEM
# ===============================
func handle_recording(delta):
	if Input.is_action_just_pressed("start_recording") and not Global.is_recording:
		start_recording()

	if Input.is_action_just_pressed("stop_recording") and Global.is_recording:
		stop_recording()

	if Global.is_recording:
		record_timer += delta

		recorded_frames.append({
			"position": global_position,
			"velocity": velocity,
			"interact": interacted_this_frame,
			"carrying": carried_box != null,
			"on_floor": is_on_floor()
			})
		#if recording_progress_bar:
				#var remaining_percent = (1.0 - (record_timer / MAX_RECORD_TIME)) * 100
				#recording_progress_bar.value = remaining_percent
			#
		# Update progress bar based on timer's remaining time
		if recording_progress_bar:
				var time_left = recording_timer.time_left
				var total_time = recording_timer.wait_time
				var remaining_percent = (time_left / total_time) * 100
				recording_progress_bar.value = remaining_percent
				
				# Update color based on remaining time
				update_progress_bar_color(time_left, total_time)
				
				# Update pulsing effect
				update_progress_bar_pulse(delta, time_left, total_time)
		#if record_timer >= MAX_RECORD_TIME:
			#stop_recording()

func start_recording():
	record_sound.play()
	recorded_frames.clear()
	#record_timer = 0
	Global.is_recording = true
	self.update_collision_for_recording()
	# Show and reset progress bar
	#if recording_progress_bar:
		#recording_progress_bar.visible = true
		#recording_progress_bar.value = 100  # Start full
	# Show and reset progress bar
	 # Start the timer
	recording_timer.start()
	# Show and reset progress bar
	if recording_progress_bar:
		recording_progress_bar.visible = true
		recording_progress_bar.value = 100
		recording_progress_bar.modulate = Color(1, 1, 1, 1)
		recording_progress_bar.scale = Vector2(1, 1)
		
		# Reset to green color
		var fill_style = recording_progress_bar.get_theme_stylebox("fill")
		if fill_style:
			fill_style.bg_color = Color(0.2, 0.8, 0.2)  # Green
	
	# Reset pulse state
	is_pulsing = false
	pulse_timer = 0.0
	
	print("Recording started")

func stop_recording():
	record_sound.play()
	
	if not Global.is_recording:
		return

	Global.is_recording = false
	self.update_collision_for_recording()
	
	#record_timer = 0
	#print("Recording stopped")
	#if recording_progress_bar:
		#recording_progress_bar.visible = false
	#
	recording_timer.stop()
	
	# Hide progress bar
	if recording_progress_bar:
		recording_progress_bar.visible = false
	create_echo.emit(recorded_frames.duplicate(true))

# ===============================
# ANIMATION UPDATE FUNCTION
# ===============================

func update_animation() -> void:
	var is_carrying = carried_box != null
	var direction_changed = (facing_direction != last_facing_direction)

	# ───────────────────────────────────────────────
	# DROP: one-shot when we stop carrying
	# ───────────────────────────────────────────────
	if was_carrying_last_frame and not is_carrying:
		anim_sprite.animation = "drop"
		anim_sprite.play()
		apply_flip()
		was_carrying_last_frame = is_carrying
		is_in_activation = false
		is_turning = false
		last_facing_direction = facing_direction
		return

	# Protect drop animation until done
	if anim_sprite.animation == "drop" and anim_sprite.is_playing():
		apply_flip()
		was_carrying_last_frame = is_carrying
		return

	# ───────────────────────────────────────────────
	# Just picked up → start activation ("carry") once
	# ───────────────────────────────────────────────
	if is_carrying and not was_carrying_last_frame:
		anim_sprite.animation = "carry"
		anim_sprite.play()
		is_in_activation = true
		is_turning = false
		apply_flip()
		last_facing_direction = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# While in activation → protect it until it finishes
	if is_in_activation:
		if anim_sprite.animation != "carry":
			anim_sprite.animation = "carry"
			anim_sprite.play()
		apply_flip()
		if not anim_sprite.is_playing() or anim_sprite.frame >= anim_sprite.sprite_frames.get_frame_count("carry") - 1:
			is_in_activation = false
		last_facing_direction = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ───────────────────────────────────────────────
	# LAND
	# ───────────────────────────────────────────────
	if landing:
		if anim_sprite.animation != "land":
			anim_sprite.animation = "land"
			anim_sprite.play()
		apply_flip()
		if anim_sprite.frame >= anim_sprite.sprite_frames.get_frame_count("land") - 1:
			landing = false
		last_facing_direction = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ───────────────────────────────────────────────
	# AIRBORNE
	# ───────────────────────────────────────────────
	if not is_on_floor():
		is_stopping = false
		was_running  = false
		is_turning   = false

		if velocity.y < 0:
			if anim_sprite.animation != "jump":
				anim_sprite.animation = "jump"
				anim_sprite.play()
		else:
			match anim_sprite.animation:
				"fall":
					# First-cycle done → hand off to the loop
					if not anim_sprite.is_playing():
						anim_sprite.animation = "fall-loop"
						anim_sprite.play()
				"fall-loop":
					pass  # already looping, nothing to do
				_:
					# Fresh entry into falling
					anim_sprite.animation = "fall"
					anim_sprite.play()

		apply_flip()
		last_facing_direction = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ───────────────────────────────────────────────
	# ON FLOOR – one-shots first
	# ───────────────────────────────────────────────
	var speed: float = abs(velocity.x)

	# ── Stop ──
	if is_stopping:
		if anim_sprite.animation != "stop":
			anim_sprite.animation = "stop"
			anim_sprite.play()
		apply_flip()
		if not anim_sprite.is_playing() or \
		   anim_sprite.frame >= anim_sprite.sprite_frames.get_frame_count("stop") - 1:
			is_stopping = false
			was_running  = false
		last_facing_direction = facing_direction
		was_carrying_last_frame = is_carrying
		return

	if speed < 5.0 and was_running:
		is_stopping = true
		anim_sprite.animation = "stop"
		anim_sprite.play()
		apply_flip()
		last_facing_direction = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ── Turn: trigger when direction flips (idle / walk / run variants) ──
	if direction_changed and not is_turning:
		var turn_anim: String
		if speed < 5.0:
			turn_anim = "idle-turn"
		elif speed < RUN_SPEED_THRESHOLD:
			turn_anim = "walk-turn"
		else:
			turn_anim = "run-turn"
		is_turning      = true
		turn_start_flip = last_facing_direction < 0   # lock OLD facing for the sprite
		anim_sprite.flip_h  = turn_start_flip
		anim_sprite.animation = turn_anim
		anim_sprite.play()
		last_facing_direction = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ── Protect turn until it finishes, then snap to new facing ──
	if is_turning:
		anim_sprite.flip_h = turn_start_flip
		if not anim_sprite.is_playing() or \
		   anim_sprite.frame >= anim_sprite.sprite_frames.get_frame_count(anim_sprite.animation) - 1:
			is_turning = false
			apply_flip()   # apply new facing_direction now
		last_facing_direction = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ── Walk / Run blend ──
	if speed >= 5.0:
		if speed < RUN_SPEED_THRESHOLD:
			if anim_sprite.animation != "walk":
				anim_sprite.animation = "walk"
				anim_sprite.play()
			anim_sprite.speed_scale = clamp(
				lerp(0.6, 1.4, (speed - WALK_SPEED_THRESHOLD) / (RUN_SPEED_THRESHOLD - WALK_SPEED_THRESHOLD)),
				0.6, 1.4
			)
		else:
			if anim_sprite.animation != "run":
				anim_sprite.animation = "run"
				anim_sprite.play()
			anim_sprite.speed_scale = 1.0
			was_running = true
	else:
		anim_sprite.speed_scale = 1.0
		if anim_sprite.animation != "idle":
			anim_sprite.animation = "idle"
			anim_sprite.play()

	apply_flip()
	last_facing_direction = facing_direction
	was_carrying_last_frame = is_carrying


func apply_flip() -> void:
	anim_sprite.flip_h = facing_direction < 0
	#this is to adjust the sprite bit when it turns
	#if anim_sprite.flip_h:
		#anim_sprite.offset = Vector2(-, 0)
	#else:
		#anim_sprite.offset = Vector2(0, 0)
 



func update_collision_for_recording():
	print("update coll")
	pass
	#set_collision_mask_value(3, not Global.is_recording)
	# true  = collide with layer 3 when NOT recording
	# false = ignore layer 3 when recording





























# ==========================
# 🎵 RECORDING START
# ==========================

func start_recording_effects():
	start_glow_pulse()
	fade_in_recording_sound()


# ==========================
# 🎵 RECORDING STOP
# ==========================

func stop_recording_effects():
	stop_glow_pulse()
	fade_out_recording_sound()


# ==========================
# ✨ GLOW PULSE
# ==========================

func start_glow_pulse():
	if glow_tween:
		glow_tween.kill()

	glow_tween = create_tween()
	glow_tween.set_loops()

	glow_tween.tween_method(
		func(value):
			anim_sprite.material.set("shader_parameter/glow_strength", value),
		0.4,
		0.9,
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	glow_tween.tween_method(
		func(value):
			anim_sprite.material.set("shader_parameter/glow_strength", value),
		0.9,
		0.4,
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_glow_pulse():
	if glow_tween:
		glow_tween.kill()

	#anim_sprite.material.set("shader_parameter/glow_strength", 0.0)#this turns it off instantlyv
	var tween = create_tween()
	tween.tween_method(
		func(value):
			anim_sprite.material.set("shader_parameter/glow_strength", value),
		anim_sprite.material.get("shader_parameter/glow_strength"),
		0,#we are fading to 0
		0.3
	)


# ==========================
# 🔊 AUDIO FADE
# ==========================
func fade_in_recording_sound():
	if audio_tween and is_instance_valid(audio_tween):
		audio_tween.kill()
	
	# Start completely silent (very low value = effectively muted)
	is_recording_sound.volume_db = -80.0
	
	is_recording_sound.play()
	
	audio_tween = create_tween()
	audio_tween.tween_property(
		is_recording_sound,           # ← target the player node itself
		"volume_db",                  # ← property to tween
		-25,                          # ← target = full volume
		0.9                           # ← duration in seconds (change to whatever feels right: 0.3–0.8)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func fade_out_recording_sound():
	if audio_tween and is_instance_valid(audio_tween):
		audio_tween.kill()
	
	audio_tween = create_tween()
	audio_tween.tween_property(
		is_recording_sound,
		"volume_db",
		-40.0,                        # ← or -60 / -80 if you want it fully silent
		2.0                           # ← your 2-second fade (fine as-is)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Stop the player only after fade completes
	audio_tween.finished.connect(func():
		is_recording_sound.stop()
		# Optional: reset volume so next play starts clean
		is_recording_sound.volume_db = 0.0
	)


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("resettable") or body.is_in_group("projectile_receiver") or body.is_in_group("projectile") or body.is_in_group("redirect_platform"):
		Global.interactable_count += 1
		Global.player_around_interactable = Global.interactable_count > 0

func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("resettable") or body.is_in_group("projectile_receiver") or body.is_in_group("projectile"  )or body.is_in_group("redirect_platform"):
		Global.interactable_count = max(0, Global.interactable_count - 1)
		Global.player_around_interactable = Global.interactable_count > 0

func die() -> void:
	print("Player hit spike → death sequence")
	
	# Disable input immediately so player can't move during death
	set_physics_process(false)
	set_process_input(false)
	CameraShake.shake(0.28)
	stop_recording()
	# Play die animation and wait for it to finish
	anim_sprite.animation = "death"
	anim_sprite.play()
	await anim_sprite.animation_finished
	
	DeathManager.trigger_death_freeze_and_fade()


func _on_recording_timer_timeout() -> void:
	if Global.is_recording:
		stop_recording()
		
		

func setup_progress_bar_style():
	if not recording_progress_bar:
		return
	
	# Create background StyleBox
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	
	# Create fill StyleBox (start green)
	var fill_style = StyleBoxFlat.new()
	original_fill_color = Color(0.2, 0.8, 0.2)  # Green
	fill_style.bg_color = original_fill_color
	fill_style.corner_radius_top_left = 5
	fill_style.corner_radius_top_right = 5
	fill_style.corner_radius_bottom_left = 5
	fill_style.corner_radius_bottom_right = 5
	
	# Apply the styles
	recording_progress_bar.add_theme_stylebox_override("background", bg_style)
	recording_progress_bar.add_theme_stylebox_override("fill", fill_style)

func update_progress_bar_color(time_left: float, total_time: float):
	# Calculate percentage remaining
	var percent_remaining = (time_left / total_time) * 100
	
	# Determine color based on remaining time
	var new_color: Color
	
	if percent_remaining > 50:
		# Green to Yellow (0-50% remaining)
		var t = (percent_remaining - 50) / 50  # 0 at 50%, 1 at 100%
		new_color = Color(
			lerp(0.8, 0.2, t),    # R: 0.8(yellow) to 0.2(green)
			lerp(0.8, 0.8, t),    # G: stays 0.8
			lerp(0.2, 0.2, t)     # B: stays 0.2
		)
	elif percent_remaining > 15:
		# Yellow to Orange (15-50% remaining)
		var t = (percent_remaining - 15) / 35  # 0 at 15%, 1 at 50%
		new_color = Color(
			lerp(1.0, 0.8, t),     # R: 1.0(orange) to 0.8(yellow)
			lerp(0.5, 0.8, t),     # G: 0.5(orange) to 0.8(yellow)
			lerp(0.0, 0.2, t)      # B: 0.0(orange) to 0.2(yellow)
		)
	else:
		# Orange to Red (0-15% remaining)
		var t = percent_remaining / 15  # 0 at 0%, 1 at 15%
		new_color = Color(
			lerp(0.8, 1.0, t),     # R: 0.8(red) to 1.0(orange)
			lerp(0.2, 0.5, t),     # G: 0.2(red) to 0.5(orange)
			lerp(0.2, 0.0, t)      # B: 0.2(red) to 0.0(orange)
		)
	
	# Apply the color
	var fill_style = recording_progress_bar.get_theme_stylebox("fill")
	if fill_style:
		fill_style.bg_color = new_color

func update_progress_bar_pulse(delta: float, time_left: float, total_time: float):
	# Check if time is low (< 3 seconds)
	var should_pulse = time_left < 3.0
	
	if should_pulse and not is_pulsing:
		# Start pulsing
		is_pulsing = true
		pulse_timer = 0.0
	elif not should_pulse and is_pulsing:
		# Stop pulsing
		is_pulsing = false
		# Reset opacity
		if recording_progress_bar:
			recording_progress_bar.modulate = Color(1, 1, 1, 1)
	
	# Apply pulse effect if active
	if is_pulsing and time_left > 0:
		pulse_timer += delta * 8  # Speed of pulse
		var pulse = (sin(pulse_timer) + 1) / 2  # Value between 0 and 1
		
		# Pulse alpha between 0.5 and 1.0, faster as time runs out
		var min_alpha = 0.5
		var max_alpha = 1.0
		var intensity = min(1.0, (3.0 - time_left) / 3.0)  # Increases as time decreases
		
		# Adjust pulse speed based on intensity
		var speed_multiplier = 1.0 + (intensity * 2)  # Up to 3x faster at end
		
		# Use different pulse timer for speed effect
		var fast_pulse = sin(pulse_timer * speed_multiplier)
		var alpha = min_alpha + ((fast_pulse + 1) / 2) * (max_alpha - min_alpha)
		
		recording_progress_bar.modulate = Color(1, 1, 1, alpha)
		

func toggle_camera_zoom() -> void:
	var target_zoom: float
	
	if is_zoomed_out:
		target_zoom = camera_zoom_zoomed
		is_zoomed_out = false
	else:
		target_zoom = camera_zoom_default
		is_zoomed_out = true
	
	is_animating = true
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(camera, "zoom", Vector2(target_zoom, target_zoom), zoom_animation_duration)
	tween.tween_callback(func(): is_animating = false)
	
func _on_zoom_animation_finished() -> void:
	is_animating = false
	current_zoom = camera.zoom.x
