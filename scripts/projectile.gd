extends CharacterBody2D
@export var speed := 120.0
var direction: Vector2 = Vector2.ZERO
var is_active := false
var spawn_position: Vector2
var ignore_platform: Node = null
var ignore_timer: float = 0.0
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_redirect: AudioStreamPlayer2D = $SfxRedirect
@onready var sfxmoving: AudioStreamPlayer2D = $Sfxmoving

# ===============================
# 🟢 READY
# ===============================
func _ready():
	spawn_position = global_position
	anim_sprite.play("idle")

# ===============================
# 🚀 LAUNCH
# ===============================
func launch(facing_direction: float):
	if is_active:
		return
	sfxmoving.play()
	direction = Vector2(facing_direction, 0)
	is_active = true
	anim_sprite.play("moving")
	update_visual_rotation()

# ===============================
# 🔄 PHYSICS
# ===============================
func _physics_process(delta):
	if not is_active:
		return

	if ignore_timer > 0:
		ignore_timer -= delta
		if ignore_timer <= 0:
			ignore_platform = null

	var collision = move_and_collide(direction * speed * delta)
	if collision:
		handle_collision(collision)

# ===============================
# 💥 COLLISION
# ===============================
func handle_collision(collision):
	var collider = collision.get_collider()

	if collider == ignore_platform:
		return

	if collider.is_in_group("redirect_platform"):
		redirect(collider, collision)
		return

	if collider.is_in_group("projectile_receiver"):
		reset_projectile()
		return

	stop()

# ===============================
# 🔁 REDIRECT
# ===============================
func redirect(platform, collision):
	#sfx_redirect.pitch_scale=randf_range(0.68, 1.1)
	sfx_redirect.play() 
	var new_direction = platform.get_redirect_direction()
	if new_direction.is_equal_approx(direction):
		reset_projectile()
		return

	ignore_platform = platform
	ignore_timer = 0.2

	global_position = platform.get_node("SpawnPoint").global_position
	#print("Rune ", rune_id, " activated by echo ", id)
	
	#rune_hit_light.enabled=true
	direction = new_direction
	update_visual_rotation()

# ===============================
# 🔄 RESET TO SPAWN
# ===============================
func reset_projectile():
	is_active = false
	sfxmoving.stop()
	
	direction = Vector2.ZERO
	global_position = spawn_position
	rotation = 0
	ignore_platform = null
	ignore_timer = 0.0
	anim_sprite.play("idle")

# ===============================
# 🛑 STOP
# ===============================
func stop():
	sfxmoving.stop()
	is_active = false
	anim_sprite.play("idle")
	reset_projectile()

# ===============================
# 🔄 ROTATE VISUAL
# ===============================
func update_visual_rotation():
	if direction != Vector2.ZERO:
		rotation = direction.angle()
