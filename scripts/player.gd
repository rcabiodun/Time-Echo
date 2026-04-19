
extends CharacterBody2D

# ============================================================
# PLAYER CONTROLLER
# Handles: movement, jumping, ledge hanging, box carrying,
#          echo recording, camera zoom, animations, death.
# ============================================================


# ============================================================
# 🎮 MOVEMENT CONSTANTS
# ============================================================
const SPEED := 240.0
const WALK_SPEED_THRESHOLD := 170.0   # Below this speed → walk animation
const RUN_SPEED_THRESHOLD  := 225.0   # Above this speed → full run animation

## Tracks whether the player was at run speed last frame (used for stop animation)
var was_running := false
## True while the stop one-shot animation is playing
var is_stopping := false

const DEFAULT_JUMP_VELOCITY := -352.0
## Active jump velocity – reduced while carrying a box 
var JUMP_VELOCITY := DEFAULT_JUMP_VELOCITY

const LEDGE_JUMP_VELOCITY := -280.0   # tweak this number
## Which way the player is visually facing: +1 = right, -1 = left
var last_facing_direction: int = 1
## True while a turn one-shot animation is playing
var is_turning: bool = false
## The flip state locked in at the start of a turn (held until the turn anim finishes)
var turn_start_flip: bool = false


# ============================================================
# ⏺  RECORDING SETTINGS
# ============================================================
## Maximum allowed recording length in seconds (timer node enforces this)
const MAX_RECORD_TIME := 15.0


# ============================================================
# ✨ JUMP FEEL – COYOTE TIME & JUMP BUFFERING
# ============================================================
@export var COYOTE_TIME      := 0.12   # Seconds after walking off a ledge where jumping is still allowed
@export var JUMP_BUFFER_TIME := 0.12   # Seconds before landing where a jump input is remembered

var coyote_timer      := 0.0
var jump_buffer_timer := 0.0


# ============================================================
# 📦 BOX CARRY (TELEKINESIS)
# ============================================================
## The box node currently being held, or null
var carried_box: Node2D = null
@export var carry_distance := 52.0     # Horizontal offset from player centre to held box

@onready var pickup_area: Area2D = $PickupArea


# ============================================================
# 🔊 AUDIO
# ============================================================
@onready var record_sound:       AudioStreamPlayer2D = $Sounds/RecordSound
@onready var jump_sound:         AudioStreamPlayer2D = $Sounds/JumpSound
@onready var is_recording_sound: AudioStreamPlayer2D = $Sounds/IsRecordingSound
@export var foot_step_1: AudioStreamPlayer2D
@export var foot_step_2: AudioStreamPlayer2D
@export var foot_step_3: AudioStreamPlayer2D
@export var foot_step_4: AudioStreamPlayer2D
var footstep_timer := 0.0
var footstep_interval := 0.35 # adjust for walk/run speed

# ============================================================
# ⏺  RECORDING STATE
# ============================================================
var record_timer:    float = 0.0
var recorded_frames: Array = []
var sfx_bus_index:   int

## Emitted when the player stops recording; carries the captured frame array
signal create_echo(frames)

@onready var recording_timer:        Timer       = $RecordingTimer
@onready var recording_progress_bar: ProgressBar = $RecordingProgressBar

## True while the progress bar low-time pulse effect is active
var is_pulsing: bool  = false
var pulse_timer: float = 0.0

## Tweens for glow and audio volume transitions
var glow_tween:  Tween
var audio_tween: Tween

## Used to detect the recording→not-recording transition each frame
var was_recording := false

var is_reviving := false
# ============================================================
# 🎬 ANIMATION STATE
# ============================================================
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D3

## True on the single frame the player touches the floor after being airborne
var landing := false
## Tracks last frame's floor state to detect the landing frame
var was_on_floor := false

## True while the carry pick-up one-shot animation is playing
var is_in_activation := false
## Whether a box was held last frame (used to detect pick-up / drop transitions)
var was_carrying_last_frame := false

## Whether the player was processing an interact input this frame (recorded into echo data)
var interacted_this_frame := false

## Current facing direction as a float: +1.0 = right, -1.0 = left
var facing_direction: float = 1.0


# ============================================================
# 📷 CAMERA ZOOM
# ============================================================
@export var camera_zoom_default:    float = 4.3
@export var camera_zoom_zoomed:     float = 1.45
@export var zoom_animation_duration: float = 0.2

var current_zoom:  float = 4.3
var is_zoomed_out: bool  = true    # true = default (far), false = zoomed in (close)
var is_animating:  bool  = false   # true while a zoom tween is running

@onready var camera: Camera2D = $Camera2D


# ============================================================
# 🪝 LEDGE HANGING
# Climbing has been removed. The player can hang from a ledge
# and jump off it; that's the full interaction.
# ============================================================
var is_ledge_hanging: bool = false

@onready var ledge_hand_ray: RayCast2D = $LedgeHandRay   # Detects the ledge wall at hand height
@onready var ledge_head_ray: RayCast2D = $LedgeHeadRay   # Detects wall at head height (blocks grab when true)
@onready var ledge_snap_ray: RayCast2D = $LedgeSnapRay   # Downward ray used to find the ledge surface Y


# ============================================================
# 🔧 INITIALISATION
# ============================================================
func _ready() -> void:
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	update_collision_for_recording()
	current_zoom   = camera_zoom_default
	camera.zoom    = Vector2(current_zoom, current_zoom)


# ============================================================
# ⌨️  INPUT (non-physics)
# ============================================================
func _input(event: InputEvent) -> void:
	# Toggle camera zoom with a dedicated action
	if event.is_action_pressed("change_camera_zoom") and not is_animating:
		toggle_camera_zoom()


# ============================================================
# 🔄 MAIN PHYSICS LOOP
# ============================================================
func _physics_process(delta: float) -> void:
	play_recording_effects()   # Handle recording start/stop VFX/SFX transitions
	apply_gravity(delta)
	update_timers(delta)
	handle_jump()
	handle_movement(delta)
	handle_interact()
	handle_recording(delta)

	# Detect the single landing frame (airborne last frame, on floor this frame)
	var currently_on_floor := is_on_floor()
	if not was_on_floor and currently_on_floor:
		landing = true
	was_on_floor = currently_on_floor

	update_animation()
	move_and_slide()
	update_carried_box_position()


# ============================================================
# 🎬 RECORDING EFFECT TRANSITIONS
# Fires start/stop helpers only on the frame the state changes.
# ============================================================
func play_recording_effects() -> void:
	if Global.is_recording != was_recording:
		was_recording = Global.is_recording
		if was_recording:
			start_recording_effects()
		else:
			stop_recording_effects()


# ============================================================
# 🌍 GRAVITY
# Suppressed while hanging so the player doesn't slide down.
# ============================================================
func apply_gravity(delta: float) -> void:
	if is_ledge_hanging:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta


# ============================================================
# ⏱  COYOTE TIME & JUMP BUFFER TIMERS
# ============================================================
func update_timers(delta: float) -> void:
	# Coyote timer: reset to full each frame on the floor, count down in the air
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# Jump buffer: store the input for a short window so pressing jump just
	# before landing still triggers correctly
	if Input.is_action_just_pressed("jump"):
		jump_sound.play()
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta


# ============================================================
# 🦘 JUMP
# Works from the floor (with coyote grace) AND from a ledge hang.
# ============================================================
func handle_jump() -> void:
	# --- Ledge hang jump ---
	# While hanging the player can press jump to push off the ledge.
	# We apply a regular jump velocity and release the hang state.
	if is_ledge_hanging:
		if Input.is_action_just_pressed("jump"):
			is_ledge_hanging = false
			velocity.y = LEDGE_JUMP_VELOCITY        # ← smaller pop
			velocity.x = -facing_direction * 80.0
			jump_buffer_timer = 0.0
			coyote_timer      = 0.0
		return
		#ip normal floor-jump logic while hanging

	# --- Normal / coyote jump ---
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y        = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer      = 0


# ============================================================
# 🏃 HORIZONTAL MOVEMENT & LEDGE GRAB CHECK
# ============================================================
func handle_movement(delta: float) -> void:
	update_ledge_rays()

	# Freeze the player in place while hanging; jump is handled above
	if is_ledge_hanging:
		velocity = Vector2.ZERO
		return

	# Check whether to grab a new ledge this frame
	if check_ledge_grab():
		_snap_to_ledge()
		return

	# Standard horizontal movement
	var direction := Input.get_axis("left", "right")
	if direction != 0:
		facing_direction = direction
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 4 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 6 * delta)
	# Footstep logic
	if is_on_floor() and abs(velocity.x) > 10:
		footstep_timer -= delta
		
		if footstep_timer <= 0:
			play_footstep()
			footstep_timer = footstep_interval
	else:
		footstep_timer = 0

# ============================================================
# ✋ INTERACT – PICK UP / DROP BOX, ROTATE PLATFORMS, LAUNCH PROJECTILES
# ============================================================
func handle_interact() -> void:
	interacted_this_frame = false

	if not Input.is_action_just_pressed("interact"):
		return

	interacted_this_frame = true

	# Drop the currently held box
	if carried_box:
		JUMP_VELOCITY = DEFAULT_JUMP_VELOCITY
		carried_box.drop()
		carried_box = null
		return

	# Scan the pickup area for something to interact with
	for body in pickup_area.get_overlapping_bodies():
		if body.is_in_group("carryable"):
			JUMP_VELOCITY = -300
			carried_box   = body
			body.pick_up(self)
			break

		if body.is_in_group("redirect_platform"):
			body.interact(self)

		if body.is_in_group("projectile"):
			body.launch(facing_direction)


# ============================================================
# 📦 CARRIED BOX POSITION UPDATE
# Called every frame to keep the box floating in front of the player.
# ============================================================
func update_carried_box_position() -> void:
	if not carried_box:
		return

	var dir: float = facing_direction if facing_direction != 0 else 1.0
	var target_pos := global_position + Vector2(dir * carry_distance, -12)
	carried_box.follow_target(target_pos)


# ============================================================
# ⏺  RECORDING SYSTEM
# ============================================================
func handle_recording(delta: float) -> void:
	if Input.is_action_just_pressed("start_recording") and not Global.is_recording:
		start_recording()
	if Input.is_action_just_pressed("stop_recording") and Global.is_recording:
		stop_recording()

	if Global.is_recording:
		record_timer += delta

		# Capture a snapshot of the player's state for this frame
		recorded_frames.append({
			"position": global_position,
			"velocity": velocity,
			"interact": interacted_this_frame,
			"carrying": carried_box != null,
			"on_floor": is_on_floor()
		})

		# Update the progress bar
		if recording_progress_bar:
			var time_left   := recording_timer.time_left
			var total_time  := recording_timer.wait_time
			var pct         := (time_left / total_time) * 100.0
			recording_progress_bar.value = pct
			update_progress_bar_color(time_left, total_time)
			update_progress_bar_pulse(delta, time_left, total_time)


func start_recording() -> void:
	record_sound.play()
	recorded_frames.clear()
	Global.is_recording = true
	update_collision_for_recording()
	recording_timer.start()

	if recording_progress_bar:
		recording_progress_bar.visible = true
		recording_progress_bar.value   = 100
		recording_progress_bar.modulate = Color(1, 1, 1, 1)
		recording_progress_bar.scale    = Vector2(1, 1)
		var fill_style = recording_progress_bar.get_theme_stylebox("fill")
		if fill_style:
			fill_style.bg_color = Color(0.2, 0.8, 0.2)   # Start green

	is_pulsing   = false
	pulse_timer  = 0.0


func stop_recording() -> void:
	if not Global.is_recording:
		return

	record_sound.play()
	Global.is_recording = false
	update_collision_for_recording()
	recording_timer.stop()

	if recording_progress_bar:
		recording_progress_bar.visible = false

	# Emit the captured frames so the echo spawner can replay them
	create_echo.emit(recorded_frames.duplicate(true))


# ============================================================
# 🎬 ANIMATION STATE MACHINE
# Priority order (highest → lowest):
#   drop → carry activation → land → ledge hang →
#   airborne → stop → turn → walk/run/idle
# ============================================================
func update_animation() -> void:
	if is_reviving:
		return  # 🔒 hands off until revive finishes
	
	var is_carrying      := carried_box != null
	var direction_changed := (facing_direction != last_facing_direction)

	# ── DROP: one-shot when the player releases a box ──────────────────────
	if was_carrying_last_frame and not is_carrying:
		anim_sprite.animation = "drop"
		anim_sprite.play()
		apply_flip()
		was_carrying_last_frame = is_carrying
		is_in_activation        = false
		is_turning              = false
		last_facing_direction   = facing_direction
		return

	# Guard: keep drop playing until it finishes
	if anim_sprite.animation == "drop" and anim_sprite.is_playing():
		apply_flip()
		was_carrying_last_frame = is_carrying
		return

	# ── CARRY ACTIVATION: one-shot on pick-up ──────────────────────────────
	if is_carrying and not was_carrying_last_frame:
		anim_sprite.animation = "carry"
		anim_sprite.play()
		is_in_activation = true
		is_turning       = false
		apply_flip()
		last_facing_direction   = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# Guard: keep carry activation playing until it finishes
	if is_in_activation:
		if anim_sprite.animation != "carry":
			anim_sprite.animation = "carry"
			anim_sprite.play()
		apply_flip()
		var last_carry_frame := anim_sprite.sprite_frames.get_frame_count("carry") - 1
		if not anim_sprite.is_playing() or anim_sprite.frame >= last_carry_frame:
			is_in_activation = false
		last_facing_direction   = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ── LAND: one-shot on touching the floor ───────────────────────────────
	if landing:
		if anim_sprite.animation != "land":
			anim_sprite.animation = "land"
			anim_sprite.play()
		apply_flip()
		var last_land_frame := anim_sprite.sprite_frames.get_frame_count("land") - 1
		if anim_sprite.frame >= last_land_frame:
			landing = false
		last_facing_direction   = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ── LEDGE HANG: looping idle while gripping a ledge ───────────────────
	if is_ledge_hanging:
		if anim_sprite.animation != "ledge-hang":
			anim_sprite.animation = "ledge-hang"
			anim_sprite.play()
		apply_flip()
		last_facing_direction   = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ── AIRBORNE ───────────────────────────────────────────────────────────
	if not is_on_floor():
		is_stopping      = false
		was_running      = false
		is_turning       = false
		is_ledge_hanging = false

		if velocity.y < 0:
			# Rising
			if anim_sprite.animation != "jump":
				anim_sprite.animation = "jump"
				anim_sprite.play()
		else:
			# Falling: play "fall" once then hand off to the looping "fall-loop"
			match anim_sprite.animation:
				"fall":
					if not anim_sprite.is_playing():
						anim_sprite.animation = "fall-loop"
						anim_sprite.play()
				"fall-loop":
					pass   # Already looping – nothing to do
				_:
					anim_sprite.animation = "fall"
					anim_sprite.play()

		apply_flip()
		last_facing_direction   = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# ── ON FLOOR ───────────────────────────────────────────────────────────
	var speed: float = abs(velocity.x)

	# Stop (one-shot when transitioning from running to idle)
	if is_stopping:
		if anim_sprite.animation != "stop":
			anim_sprite.animation = "stop"
			anim_sprite.play()
		apply_flip()
		var last_stop_frame := anim_sprite.sprite_frames.get_frame_count("stop") - 1
		if not anim_sprite.is_playing() or anim_sprite.frame >= last_stop_frame:
			is_stopping = false
			was_running = false
		last_facing_direction   = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# Trigger stop animation when speed drops from running to near-zero
	if speed < 5.0 and was_running:
		is_stopping           = true
		anim_sprite.animation = "stop"
		anim_sprite.play()
		apply_flip()
		last_facing_direction   = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# Turn (one-shot when the player reverses direction)
	if direction_changed and not is_turning:
		var turn_anim: String
		if speed < 5.0:
			turn_anim = "idle-turn"
		elif speed < RUN_SPEED_THRESHOLD:
			turn_anim = "walk-turn"
		else:
			turn_anim = "run-turn"
		is_turning      = true
		turn_start_flip = last_facing_direction < 0   # Lock OLD facing for the duration
		anim_sprite.flip_h    = turn_start_flip
		anim_sprite.animation = turn_anim
		anim_sprite.play()
		last_facing_direction   = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# Guard: hold the old facing flip until the turn finishes
	if is_turning:
		anim_sprite.flip_h = turn_start_flip
		var last_turn_frame := anim_sprite.sprite_frames.get_frame_count(anim_sprite.animation) - 1
		if not anim_sprite.is_playing() or anim_sprite.frame >= last_turn_frame:
			is_turning = false
			apply_flip()
		last_facing_direction   = facing_direction
		was_carrying_last_frame = is_carrying
		return

	# Walk / Run blend
	if speed >= 5.0:
		if speed < RUN_SPEED_THRESHOLD:
			if anim_sprite.animation != "walk":
				anim_sprite.animation = "walk"
				anim_sprite.play()
			# Scale playback speed with movement speed for a natural blend
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
		# Idle
		anim_sprite.speed_scale = 1.0
		if anim_sprite.animation != "idle":
			anim_sprite.animation = "idle"
			anim_sprite.play()

	apply_flip()
	last_facing_direction   = facing_direction
	was_carrying_last_frame = is_carrying


## Sets the sprite's horizontal flip to match the current facing direction.
func apply_flip() -> void:
	anim_sprite.flip_h = facing_direction < 0


## Stub – re-enable/disable collision layers when recording state changes if needed.
func update_collision_for_recording() -> void:
	pass


# ============================================================
# 🌟 RECORDING VFX / SFX WRAPPERS
# ============================================================
func start_recording_effects() -> void:
	start_glow_pulse()
	fade_in_recording_sound()


func stop_recording_effects() -> void:
	stop_glow_pulse()
	fade_out_recording_sound()


# ============================================================
# ✨ GLOW PULSE (shader parameter tween loop)
# ============================================================
func start_glow_pulse() -> void:
	if glow_tween:
		glow_tween.kill()

	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_method(
		func(v): anim_sprite.material.set("shader_parameter/glow_strength", v),
		0.4, 0.9, 1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_method(
		func(v): anim_sprite.material.set("shader_parameter/glow_strength", v),
		0.9, 0.4, 1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_glow_pulse() -> void:
	if glow_tween:
		glow_tween.kill()
	# Fade glow back to zero smoothly instead of snapping off
	var tween := create_tween()
	tween.tween_method(
		func(v): anim_sprite.material.set("shader_parameter/glow_strength", v),
		anim_sprite.material.get("shader_parameter/glow_strength"),
		0.0, 0.3
	)


# ============================================================
# 🔊 RECORDING AMBIENT SOUND – FADE IN / OUT
# ============================================================
func fade_in_recording_sound() -> void:
	if audio_tween and is_instance_valid(audio_tween):
		audio_tween.kill()
	is_recording_sound.volume_db = -80.0
	is_recording_sound.play()
	audio_tween = create_tween()
	audio_tween.tween_property(is_recording_sound, "volume_db", -25.0, 0.9)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func fade_out_recording_sound() -> void:
	if audio_tween and is_instance_valid(audio_tween):
		audio_tween.kill()
	audio_tween = create_tween()
	audio_tween.tween_property(is_recording_sound, "volume_db", -40.0, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	audio_tween.finished.connect(func():
		is_recording_sound.stop()
		is_recording_sound.volume_db = 0.0
	)


# ============================================================
# 🏁 INTERACTABLE TRACKING (proximity indicator)
# ============================================================
func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("resettable")         or body.is_in_group("projectile_receiver") \
	or body.is_in_group("projectile")         or body.is_in_group("redirect_platform"):
		Global.interactable_count += 1
		Global.player_around_interactable = Global.interactable_count > 0


func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("resettable")         or body.is_in_group("projectile_receiver") \
	or body.is_in_group("projectile")         or body.is_in_group("redirect_platform"):
		Global.interactable_count = max(0, Global.interactable_count - 1)
		Global.player_around_interactable = Global.interactable_count > 0


# ============================================================
# 💀 DEATH
# ============================================================
func die() -> void:
	Input.vibrate_handheld(700)  # vibrate for 200 milliseconds
	set_physics_process(false)
	set_process_input(false)
	CameraShake.shake(0.28)
	stop_recording()
	anim_sprite.animation = "death"
	anim_sprite.play()
	await anim_sprite.animation_finished
	DeathManager.trigger_death_freeze_and_fade()


# ============================================================
# ⏰ RECORDING TIMER CALLBACK
# Auto-stops recording when the max time is reached.
# ============================================================
func _on_recording_timer_timeout() -> void:
	if Global.is_recording:
		stop_recording()


# ============================================================
# 📊 PROGRESS BAR – COLOR GRADIENT
# Green → Yellow → Orange → Red as time runs out.
# ============================================================
func update_progress_bar_color(time_left: float, total_time: float) -> void:
	var pct := (time_left / total_time) * 100.0
	var new_color: Color

	if pct > 50:
		var t := (pct - 50.0) / 50.0
		new_color = Color(lerp(0.8, 0.2, t), 0.8, 0.2)
	elif pct > 15:
		var t := (pct - 15.0) / 35.0
		new_color = Color(lerp(1.0, 0.8, t), lerp(0.5, 0.8, t), lerp(0.0, 0.2, t))
	else:
		var t := pct / 15.0
		new_color = Color(lerp(0.8, 1.0, t), lerp(0.2, 0.5, t), lerp(0.2, 0.0, t))

	var fill_style = recording_progress_bar.get_theme_stylebox("fill")
	if fill_style:
		fill_style.bg_color = new_color


# ============================================================
# 📊 PROGRESS BAR – PULSE EFFECT (last 3 seconds)
# Opacity oscillates faster as time approaches zero.
# ============================================================
func update_progress_bar_pulse(delta: float, time_left: float, total_time: float) -> void:
	var should_pulse := time_left < 3.0

	if should_pulse and not is_pulsing:
		is_pulsing  = true
		pulse_timer = 0.0
	elif not should_pulse and is_pulsing:
		is_pulsing = false
		if recording_progress_bar:
			recording_progress_bar.modulate = Color(1, 1, 1, 1)

	if is_pulsing and time_left > 0:
		pulse_timer += delta * 8.0
		var intensity        = min(1.0, (3.0 - time_left) / 3.0)
		var speed_multiplier = 1.0 + intensity * 2.0
		var alpha            := 0.5 + ((sin(pulse_timer * speed_multiplier) + 1.0) / 2.0) * 0.5
		if recording_progress_bar:
			recording_progress_bar.modulate = Color(1, 1, 1, alpha)


# ============================================================
# 📷 CAMERA ZOOM TOGGLE
# ============================================================
func toggle_camera_zoom() -> void:
	var target_zoom := camera_zoom_zoomed if is_zoomed_out else camera_zoom_default
	is_zoomed_out = not is_zoomed_out
	is_animating  = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(camera, "zoom", Vector2(target_zoom, target_zoom), zoom_animation_duration)
	tween.tween_callback(func(): is_animating = false)


func _on_zoom_animation_finished() -> void:
	is_animating = false
	current_zoom = camera.zoom.x


# ============================================================
# 🪝 LEDGE DETECTION HELPERS
# ============================================================

## Rotates all ledge rays to match the current facing direction each frame.
func update_ledge_rays() -> void:
	var dir := float(facing_direction)
	ledge_hand_ray.target_position.x = abs(ledge_hand_ray.target_position.x) * dir
	ledge_head_ray.target_position.x = abs(ledge_head_ray.target_position.x) * dir
	ledge_snap_ray.position.x        = abs(ledge_snap_ray.position.x)        * dir
	ledge_snap_ray.force_raycast_update()
	ledge_hand_ray.force_raycast_update()
	ledge_head_ray.force_raycast_update()


## Returns true when the player should grab a ledge:
## - hand ray hits a wall at hand height
## - head ray is clear (so the player isn't fully below a surface)
## - not on the floor, not already hanging
## - not moving sharply upward
func check_ledge_grab() -> bool:
	if is_on_floor() or is_ledge_hanging:
		return false
	if velocity.y < -50.0:
		return false   # Don't grab on the way up
	return ledge_hand_ray.is_colliding() and not ledge_head_ray.is_colliding()


## Snaps the player to the ledge hang position and stores the stand-up target.
func _snap_to_ledge() -> void:
	is_ledge_hanging = true
	velocity         = Vector2.ZERO

	if ledge_snap_ray.is_colliding():
		var surface_y:   float = ledge_snap_ray.get_collision_point().y
		var half_height: float = get_collision_half_height()
		# Pull this offset number up or down until the hands sit flush with the ledge.
		# Start at half_height + ~8 and tweak from there.
		global_position.y = surface_y + half_height + 8.0
	else:
		global_position.y -= -5.0
## Returns half the height of the player's collision rectangle.
## Used when calculating the exact stand position above a ledge surface.
func get_collision_half_height() -> float:
	var shape_owner := $CollisionShape2D
	if shape_owner and shape_owner.shape is RectangleShape2D:
		return (shape_owner.shape as RectangleShape2D).size.y / 2.0
	return 20.0   # Safe fallback
	
func _play_die_animation():
	#anim_sprite.play("death")
	set_physics_process(false)
	set_process_input(false)
	print("playing death animation")
	anim_sprite.animation = "death"
	anim_sprite.play()
	await anim_sprite.animation_finished 

func revive():
	#set_physics_process(true)
	#set_process_input(true)
	is_reviving = true
	anim_sprite.play_backwards("revive")
	await anim_sprite.animation_finished
	is_reviving = false
	set_physics_process(true)
	set_process_input(true)
	
func _finish_die_animation():
	#anim_sprite.play("death")
	set_physics_process(true)
	set_process_input(true)
	 
	

func play_footstep():
	var footsteps = [
		foot_step_1,
		foot_step_2,
		foot_step_3,
		foot_step_4
	]
	
	var random_step = footsteps[randi() % footsteps.size()]
	
	# Randomize pitch (slight variation)
	random_step.pitch_scale = randf_range(0.7, 2.5)
	
	random_step.play()
