extends CharacterBody2D

# ===============================
# 🎮 MOVEMENT CONSTANTS
# ===============================
const SPEED := 200.0
const JUMP_VELOCITY := -340.0
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
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

#func _ready():
	# Make sure player collides with world + platforms, etc.
	# but initially set based on recording state
	

func _ready() -> void:
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	update_collision_for_recording()
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
			print("player dropping box")
			carried_box.drop()
			carried_box = null
			
			return

		# Try picking up nearby carryable object
		for body in pickup_area.get_overlapping_bodies():
			var box = body# StaticBody → Box root
			
			if box and box.is_in_group("carryable"):
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

		if record_timer >= MAX_RECORD_TIME:
			stop_recording()

func start_recording():
	record_sound.play()
	recorded_frames.clear()
	record_timer = 0
	Global.is_recording = true
	self.update_collision_for_recording()
	print("Recording started")

func stop_recording():
	record_sound.play()
	
	if not Global.is_recording:
		return

	Global.is_recording = false
	self.update_collision_for_recording()
	
	record_timer = 0
	print("Recording stopped")
	create_echo.emit(recorded_frames.duplicate(true))

# ===============================
# ANIMATION UPDATE FUNCTION
# ===============================

func update_animation() -> void:
	var is_carrying = carried_box != null
	
	# ───────────────────────────────────────────────
	# DROP: one-shot when we stop carrying
	# ───────────────────────────────────────────────
	if was_carrying_last_frame and not is_carrying:
		anim_sprite.animation = "drop"
		anim_sprite.play()
		apply_flip()
		was_carrying_last_frame = is_carrying
		is_in_activation = false   # reset if somehow stuck
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
		apply_flip()
		was_carrying_last_frame = is_carrying
		return   # give it at least one full frame
	
	# ───────────────────────────────────────────────
	# While in activation → protect it until it finishes
	# ───────────────────────────────────────────────
	if is_in_activation:
		if anim_sprite.animation != "carry":
			# something forced it away → put it back
			anim_sprite.animation = "carry"
			anim_sprite.play()
		
		apply_flip()
		
		# Check if animation actually completed
		if not anim_sprite.is_playing() or anim_sprite.frame >= anim_sprite.sprite_frames.get_frame_count("carry") - 1:
			is_in_activation = false
			# Optional: go to a specific frame/animation right after, e.g.
			# anim_sprite.animation = "idle"
			# anim_sprite.play()
		
		was_carrying_last_frame = is_carrying
		return   # ← this prevents normal animations from overriding during activation
	
	# ───────────────────────────────────────────────
	# Normal animations — only reached AFTER activation OR when not carrying
	# ───────────────────────────────────────────────
	if landing:
		if anim_sprite.animation != "land":
			anim_sprite.animation = "land"
			anim_sprite.play()
		apply_flip()
		if anim_sprite.frame >= anim_sprite.sprite_frames.get_frame_count("land") - 1:
			landing = false
		was_carrying_last_frame = is_carrying
		return
	
	if not is_on_floor():
		if velocity.y < 0:
			if anim_sprite.animation != "jump":
				anim_sprite.animation = "jump"
				anim_sprite.play()
		else:
			if anim_sprite.animation != "fall":
				anim_sprite.animation = "fall"
				anim_sprite.play()
		apply_flip()
		was_carrying_last_frame = is_carrying
		return
	
	if velocity.x != 0:
		if anim_sprite.animation != "walk":
			anim_sprite.animation = "walk"
			anim_sprite.play()
	else:
		if anim_sprite.animation != "idle":
			anim_sprite.animation = "idle"
			anim_sprite.play()
	
	apply_flip()
	was_carrying_last_frame = is_carrying
func apply_flip() -> void:
	anim_sprite.flip_h = facing_direction < 0
	
	if anim_sprite.flip_h:
		anim_sprite.offset = Vector2(-20, 0)
	else:
		anim_sprite.offset = Vector2(0, 0)
 



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
	CameraShake.shake(0.25)

	# Trigger the whole effect from the global manager
	DeathManager.trigger_death_freeze_and_fade()
	
	# Optional: disable player input/movement immediately
	set_physics_process(false)
	set_process_input(false)
