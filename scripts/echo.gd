extends CharacterBody2D

# ===============================
# 🎞 PLAYBACK DATA
# ===============================
var playback_frames: Array = []
var playback_index: int = 0
var echo_id: int = -1
var playback_finished := false
var recorded_on_floor: bool = false

# ===============================
# 📦 CARRY SYSTEM
# ===============================
var carried_box: Node2D = null
@export var carry_distance := 52.0
var facing_direction: float = 1.0
@onready var pickup_area: Area2D = $PickupArea

# ===============================
# 🎭 ANIMATION
# ===============================
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D2

var was_carrying_last_frame := false
var was_on_floor: bool = false
var landing := false
var is_in_activation := false

# Death timer
@onready var death_timer: Timer = $DeathTimer

# ===============================
# 👻 GHOST TRAIL SETTINGS
# ===============================
@export var ghost_strength := 0.2 # starting opacity of ghost
@export var trail_fade := 0.15     # trail fade speed
@export var ghost_tint := Color(0.5, 0.7, 1.0, 1.0) # ghost color
@export var faded_opacity := 0.7   # main echo opacity

# ===============================
# 🟢 READY
# ===============================
func _ready():
	death_timer.timeout.connect(_on_death_timer_timeout)
	
	# Start fully transparent
	anim_sprite.modulate.a = 0.0
	
	# Smooth fade-in to faded opacity
	var tween = create_tween()
	tween.tween_property(anim_sprite, "modulate:a", faded_opacity, 0.5) # fade in to 40% opacity
	
	# Assign shader for ghost trail
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = get_ghost_shader_code()
	anim_sprite.material = mat

# ===============================
# 🚀 START PLAYBACK
# ===============================
func start_playback(frames: Array):
	if frames.is_empty():
		queue_free()
		return
		
	playback_frames = frames.duplicate(true)
	playback_index = 0
	playback_finished = false
	
	global_position = playback_frames[0]["position"]
	velocity = playback_frames[0]["velocity"]
	recorded_on_floor = playback_frames[0].get("on_floor", false)
	
	# Snap to floor to prevent levitation
	if recorded_on_floor:
		velocity.y = 0.1
		move_and_collide(Vector2(0, 2))
	
	if abs(velocity.x) < 0.1:
		velocity.x = 0
	
	was_carrying_last_frame = playback_frames[0].get("carrying", false)
	was_on_floor = recorded_on_floor
	
	landing = false
	is_in_activation = false
	
	# Force correct starting animation
	if recorded_on_floor and velocity.x == 0:
		anim_sprite.animation = "idle"
		anim_sprite.play()
		apply_flip()
	else:
		update_animation()

# ===============================
# 🔄 MAIN PHYSICS / PLAYBACK
# ===============================
func _physics_process(delta):
	if playback_finished:
		velocity = Vector2.ZERO
		if recorded_on_floor:
			move_and_collide(Vector2(0, 2))
		move_and_slide()
		update_animation()
		update_ghost_trail()
		return
	
	# Move the frame fetching earlier so we can use this frame's velocity for the spawn condition
	if playback_index >= playback_frames.size():
		velocity = Vector2.ZERO
		if recorded_on_floor:
			move_and_collide(Vector2(0, 2))
		move_and_slide()
		playback_finished = true
		if death_timer.is_stopped():
			death_timer.start()
		update_ghost_trail()
		return
	
	var frame = playback_frames[playback_index]
	velocity = frame["velocity"]
	recorded_on_floor = frame.get("on_floor", false)
	if abs(velocity.x) < 0.1:
		velocity.x = 0
	if velocity.x != 0:
		facing_direction = sign(velocity.x)
	if frame.get("interact", false):
		handle_interaction()
	if recorded_on_floor and velocity.y == 0:
		velocity.y = 0.1
	
	# Spawn ghost trail every 2 frames, but only if moving (prevents duplicates during stops)
	if playback_index % 2 == 0 and (abs(velocity.x) > 0.1 or abs(velocity.y) > 0.1):
		var trail = preload("res://scenes/characters/echo_trail.tscn").instantiate()
		get_parent().add_child(trail)
		trail.setup(anim_sprite.animation, anim_sprite.frame, global_position, anim_sprite.flip_h)
	
	move_and_slide()
	var currently_on_floor = recorded_on_floor
	if not was_on_floor and currently_on_floor:
		landing = true
	was_on_floor = currently_on_floor
	
	update_carried_box_position()
	update_animation()
	update_ghost_trail()
	playback_index += 1
# ===============================
# ✋ INTERACTION
# ===============================
func handle_interaction():
	if carried_box:
		carried_box.drop()
		carried_box = null
		return
		
	for body in pickup_area.get_overlapping_bodies():
		if body.is_in_group("carryable"):
			carried_box = body
			body.pick_up(self)
			break
		if body and body.is_in_group("redirect_platform"):
				#body.begin_interaction(self)
				#body.rotate_platform()
				body.interact(self)

# ===============================
# 📦 CARRY FOLLOW
# ===============================
func update_carried_box_position():
	if carried_box:
		var target_pos = global_position + Vector2(facing_direction * carry_distance, -12)
		carried_box.follow_target(target_pos)

# ===============================
# 🎭 ANIMATION LOGIC
# ===============================
func update_animation() -> void:
	var is_carrying = carried_box != null
	var on_floor = recorded_on_floor
	
	if was_carrying_last_frame and not is_carrying:
		anim_sprite.animation = "drop"
		anim_sprite.play()
		apply_flip()
		was_carrying_last_frame = is_carrying
		is_in_activation = false
		return

	if anim_sprite.animation == "drop" and anim_sprite.is_playing():
		apply_flip()
		was_carrying_last_frame = is_carrying
		return

	if is_carrying and not was_carrying_last_frame:
		anim_sprite.animation = "carry"
		anim_sprite.play()
		is_in_activation = true
		apply_flip()
		was_carrying_last_frame = is_carrying
		return

	if is_in_activation:
		if anim_sprite.animation != "carry":
			anim_sprite.animation = "carry"
			anim_sprite.play()
		apply_flip()
		if not anim_sprite.is_playing() or anim_sprite.frame >= anim_sprite.sprite_frames.get_frame_count("carry") - 1:
			is_in_activation = false
		was_carrying_last_frame = is_carrying
		return

	if landing:
		if anim_sprite.animation != "land":
			anim_sprite.animation = "land"
			anim_sprite.play()
		apply_flip()
		if anim_sprite.frame >= anim_sprite.sprite_frames.get_frame_count("land") - 1:
			landing = false
		was_carrying_last_frame = is_carrying
		return

	if not on_floor:
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

# ===============================
# 🖼 FLIP
# ===============================
func apply_flip() -> void:
	anim_sprite.flip_h = facing_direction < 0
	anim_sprite.offset = Vector2(-20, 0) if anim_sprite.flip_h else Vector2(0, 0)

# ===============================
# 👻 UPDATE GHOST TRAIL
# ===============================
func update_ghost_trail():
	var mat := anim_sprite.material as ShaderMaterial
	if mat:
		# Set ghost parameters
		mat.set_shader_parameter("ghost_strength", ghost_strength)
		mat.set_shader_parameter("trail_fade", trail_fade)
		mat.set_shader_parameter("ghost_tint", ghost_tint)
		
		# Only offset trail when moving
		var motion_offset := Vector2.ZERO
		if abs(velocity.x) > 0.1 or abs(velocity.y) > 0.1:
			motion_offset = Vector2(-0.01 * facing_direction, 0.0)
		mat.set_shader_parameter("uv_offset", motion_offset)

# ===============================
# ☠️ CLEANUP
# ===============================
func set_echo_id(id: int):
	echo_id = id

func _on_death_timer_timeout():
	print("deleting echo")
	if carried_box:
		carried_box.drop()
		carried_box = null
	queue_free()

# ===============================
# 🎨 GHOST SHADER CODE
# ===============================
func get_ghost_shader_code() -> String:
	return """
shader_type canvas_item;

uniform float ghost_strength = 0.5;    // opacity of trailing ghosts
uniform float trail_fade = 0.15;       // how quickly trail fades
uniform vec4 ghost_tint = vec4(0.5,0.7,1.0,1.0); // ghost color
uniform vec2 uv_offset = vec2(0.0,0.0);

void fragment() {
    // sample the base sprite texture
    vec4 tex_color = texture(TEXTURE, UV);
    
    // main sprite always fully visible
    //vvec4 base_color = tex_color;
    vec4 base_color = tex_color * COLOR.a; // multiply by modulate alpha
    // ghost trail overlay (only shows when uv_offset != 0)
    vec4 ghost_color = vec4(0.0);
    if (uv_offset.x != 0.0 || uv_offset.y != 0.0) {
        ghost_color = texture(TEXTURE, UV + uv_offset);
        ghost_color.rgb *= ghost_tint.rgb;
        ghost_color.a *= ghost_strength * (1.0 - trail_fade);
    }
    
    // combine base sprite with ghost overlay
    COLOR = base_color + ghost_color;
}
"""
