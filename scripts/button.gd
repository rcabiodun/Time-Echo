
extends Area2D
# This signal tells the world:
# "A button linked to door_id/invisible_floor_id has changed state"
signal button_state_changed(attached_items_ids: Dictionary, pressed: bool,echo_id:int)
# game_enums.gd
enum ALLOWEDACTIVATORS { PLAYER, ECHO }
# The ID of the door this button controls
@export var door_id: String = "A"
@export var invisible_floor_id: String = "floor:A"
@export var allowed_activator:ALLOWEDACTIVATORS=ALLOWEDACTIVATORS.ECHO
# Tracks whether the button is currently being pressed
var is_pressed := false
@onready var rune_requirement = $RuneRequirement
@export var reject_material: ShaderMaterial
@export var glow_material: ShaderMaterial
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var reject_sound: AudioStreamPlayer2D = $RejectSound
@onready var idle_sound: AudioStreamPlayer2D = $IdleSound
@onready var success_sound: AudioStreamPlayer2D = $SuccessSound


#@onready var sprite = $Sprite2D # or whatever renders your button
var reject_tween: Tween
var glow_tween: Tween
var _required_runes: Array[String] = []


@export var required_runes: Array[String]:
	set(value):
		_required_runes = value
		# Only propagate if the node is valid
		if is_instance_valid(rune_requirement):
			rune_requirement.required_runes = value
	get:
		# If RuneRequirement exists and has a valrejectedue, return that; else return backing
		if is_instance_valid(rune_requirement) and rune_requirement.required_runes.size() > 0:
			return rune_requirement.required_runes
		return _required_runes

#func _ready():
	## Propagate inspector values manually at runtime to ensure RuneRequirement has them
	#rune_requirement.required_runes = _required_runes
	#sprite.play("idle")
	#idle_sound.play()
	#print("Button backing _required_runes:", _required_runes)
	#print("Button property required_runes:", required_runes)
	#print("Button required_runes:", rune_requirement.required_runes)
	#
func _ready():
	# Force loop on the stream resource
	

	sprite.play("idle")
	#idle_sound.play()
	#_play_sound(idle_)
	rune_requirement.required_runes = _required_runes
	#sprite.play("idle")
	#idle_sound.play()
	print("Button backing _required_runes:", _required_runes)
	print("Button property required_runes:", required_runes)
	print("Button required_runes:", rune_requirement.required_runes)
	
func _on_body_entered(body: Node2D) -> void:
	var correct_activator = false
	if allowed_activator == ALLOWEDACTIVATORS.ECHO:
		if body.is_in_group("echo") and rune_requirement.are_required_runes_active_for_echo(body.echo_id):
			correct_activator = true
			# normal press logic...
			is_pressed = true
			print("Emmitting byutton signal with echo id" + str(body.echo_id))
			button_state_changed.emit({"door_id":door_id,"invisible_floor_id":invisible_floor_id}, is_pressed, body.echo_id)
		elif body.is_in_group("echo") and not rune_requirement.are_required_runes_active_for_echo(body.echo_id):
			print("ACtivator has disappeared")
	elif allowed_activator == ALLOWEDACTIVATORS.PLAYER:
		if body.is_in_group("player"):
			correct_activator = true
			# normal press...
			is_pressed = true
			print("Emmitting byutton signal")
			
			button_state_changed.emit({"door_id":door_id,"invisible_floor_id":invisible_floor_id}, is_pressed)
	
	if not correct_activator and not is_pressed:
		#reject_sound.play()i
		sprite.play("rejected")
		# Wrong activator → spark / reject!
		_play_sound(reject_sound)
	else:
		_play_sound(idle_sound)
		
		sprite.play("accepted")
		
		play_success_glow()

func play_success_glow():
	if not glow_material:
		return
	# Apply to sprite (or separate glow child)
	sprite.material = glow_material
	glow_material.set_shader_parameter("active", true)
	glow_material.set_shader_parameter("glow_intensity", 0.0) # start from 0
	if glow_tween:
		glow_tween.kill()
	glow_tween = create_tween()
	glow_tween.set_parallel(true)
	# Gentle ramp in
	glow_tween.tween_property(glow_material, "shader_parameter/glow_intensity", 1.8, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Then settle to a soft idle glow while pressed
	glow_tween.tween_property(glow_material, "shader_parameter/glow_intensity", 1.2, 1.8)\
		.set_delay(0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func play_reject_effect(duration := 0.6):
	if not reject_material:
		return
	# Option A: Add overlay material (cleanest)
	sprite.material = reject_material # or add to a separate ColorRect child
	reject_material.set_shader_parameter("active", true)
	reject_material.set_shader_parameter("intensity", 1.8)
	if reject_tween:
		reject_tween.kill()
	reject_tween = create_tween()
	reject_tween.tween_property(reject_material, "shader_parameter/intensity", 0.0, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	reject_tween.tween_callback(func():
		reject_material.set_shader_parameter("active", false)
		# sprite.material = null # if you want to remove it completely
	)

func _on_body_exited(body: Node2D) -> void:
	sprite.play("idle")
	#if not idle_sound.is_playing():
		#idle_sound.play()
	if allowed_activator == ALLOWEDACTIVATORS.ECHO:
		if body.is_in_group("echo") and is_pressed:
			is_pressed = false
			button_state_changed.emit({"door_id":door_id,"invisible_floor_id":invisible_floor_id}, is_pressed)
			sprite.play("idle")
			_fade_out_glow()
			_play_sound(success_sound)
			print("Activator has disappearead")
	elif allowed_activator == ALLOWEDACTIVATORS.PLAYER:
		if body.is_in_group("player") and is_pressed:
			is_pressed = false
			sprite.play("idle")
			
			button_state_changed.emit({"door_id":door_id,"invisible_floor_id":invisible_floor_id}, is_pressed)
			_fade_out_glow()

# ────────────────────────────────────────────────
# NEW: Helper to cleanly fade out glow when released
# ────────────────────────────────────────────────
func _fade_out_glow():
	if not glow_material:
		return
	
	if glow_tween:
		glow_tween.kill()
	
	glow_tween = create_tween()
	glow_tween.tween_property(glow_material, "shader_parameter/glow_intensity", 0.0, 0.7)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	
	glow_tween.tween_callback(func():
		glow_material.set_shader_parameter("active", false)
		# Restore original material (whatever was set in the editor / before glow)
		sprite.material = null   # ← most common & safe choice
		# Alternative if you have a specific original material:
		# sprite.material = preload("res://your_original_material.tres")
	)


func _play_sound(sound: AudioStreamPlayer2D):
	# Stop all non-idle sounds before playing a new one
	for s in [reject_sound, idle_sound, success_sound]:
		if s != sound and s.is_playing():
			s.stop()
	if not sound.is_playing():
		sound.play()
