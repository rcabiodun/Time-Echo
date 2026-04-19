extends Area2D

# Unique ID for this rune in the level
@export var rune_id: String = "R1"
@onready var sfx_rune_hit: AudioStreamPlayer2D = $SfxRuneHit
@onready var rune_hit_light: PointLight2D = $RuneHitLight
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var rune_player_hit_light: PointLight2D = $RunePlayerHitLight
@onready var hit_particles: GPUParticles2D = $HitParticles

# Which echoes have activated this rune
var activated_by_echo_ids: Array[int] = []

func _ready() -> void:
	animated_sprite_2d.play("offline")
	#hit_particles.restart()
func _on_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("echo"):
		#hit_particles.restart()
		var id = body.echo_id
		if id not in activated_by_echo_ids:
			Input.vibrate_handheld(200) 
			activated_by_echo_ids.append(id)
			print("Rune ", rune_id, " activated by echo ", id)
			sfx_rune_hit.pitch_scale=randf_range(0.2, 1.0)
			animated_sprite_2d.play("online")
			sfx_rune_hit.play()
			rune_hit_light.enabled=true
			# Notify doors to re-check rune status
			#for door in get_tree().get_nodes_in_group("doors"):
				#door._check_runes_now(id)
	elif body.is_in_group("player") and Global.is_recording:
		Input.vibrate_handheld(200) 
		hit_particles.restart()
		if rune_hit_light.enabled:
			rune_hit_light.enabled=false
		animated_sprite_2d.play("blink")
		sfx_rune_hit.play()
		rune_player_hit_light.enabled=true
	elif body.is_in_group("player") and not Global.is_recording:
		rune_player_hit_light.enabled=false
	
	
		
		
		
		

func _process(delta: float) -> void:
	if rune_player_hit_light.enabled and not Global.is_recording:
		print("Turning off rune player light")
		rune_player_hit_light.enabled=false
# Called by level reset system
func reset_rune_if_needed(existing_echo_ids: Array[int]):
	# Remove activations from echoes that no longer exist
	activated_by_echo_ids = activated_by_echo_ids.filter(
		func(id): return id in existing_echo_ids
	)
