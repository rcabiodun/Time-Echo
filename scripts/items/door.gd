#extends StaticBody2D
#
## The ID this door listens for
#@export var door_id: String = "A"
#
## How many buttons with this ID must be pressed
#@export var required_buttons: int = 1
#
#var current_button_echo_id: int = -1
#
##@onready var rune_requirement = $RuneRequirement
#
## Backing variable
  #
##@onready var rune_requirement = $RuneRequirement
#
#
#
## Tracks how many linked buttons are currently pressed
#var pressed_count := 0
#
## References to door visuals and collision
#@onready var collision = $CollisionShape2D
#@onready var sprite = $Sprite2D
#@onready var rune_requirement = $RuneRequirement
#@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
#@onready var idle_sound: AudioStreamPlayer2D = $Sounds/IdleSound
#@onready var activation_sound: AudioStreamPlayer2D = $Sounds/ActivationSound
#@onready var deactivation_sound: AudioStreamPlayer2D = $Sounds/DeactivationSound
#@onready var point_light_2d: PointLight2D = $PointLight2D
#
#
##var _required_runes: Array[String] = []
##
##@export var required_runes: Array[String]:
	##set(value):
		##_required_runes = value
		### Only propagate if the node is valid
		##if is_instance_valid(rune_requirement):
			##rune_requirement.required_runes = value
	##get:
		### If RuneRequirement exists and has a value, return that; else return backing
		##if is_instance_valid(rune_requirement) and rune_requirement.required_runes.size() > 0:
			##return rune_requirement.required_runes
		##return _required_runes
#
##
##func _ready():
	### Propagate inspector values manually at runtime to ensure RuneRequirement has them
	##rune_requirement.required_runes = _required_runes
##
	##print("Door backing _required_runes:", _required_runes)
	##print("Door property required_runes:", required_runes)
	##print("RuneRequirement required_runes:", rune_requirement.required_runes)
#
## Called by the level manager whenever ANY button changes state
#
#func _ready() -> void:
	#_play_sound(idle_sound)
	#animated_sprite_2d.play("idle")
	#_turn_on_light()
#func _turn_on_light():
	#point_light_2d.energy = 1.8 + randf() * 0.3
#
#func _turn_off_light():
	#point_light_2d.energy = 0
##func _process(delta):
	#
#func register_button_event(id: String, pressed: bool,echo_id:int=0):
	## Ignore signals meant for other doors
	#if id != door_id:
		#return
#
	## Update how many buttons are currently pressed
	#if pressed:
		#pressed_count += 1
		#current_button_echo_id=echo_id
	#else:
		#pressed_count -= 1
		#if pressed_count == 0:
			#current_button_echo_id=-1
#
	## Prevent negative values or overflow
	#pressed_count = clamp(pressed_count, 0, required_buttons)
#
	## Open only if enough buttons are pressed
	#if pressed_count >= required_buttons:
		#open()
	#else:
		#close()
		#
#
#
#func open():
	#print("opening door")
	#_play_sound(deactivation_sound)
	#animated_sprite_2d.play("deactivate")
	## Turn OFF door layer so player can't collide
	#set_collision_layer_value(4, false)
	#sprite.modulate.a = 0.3
	#_turn_off_light()
#
#func close():
	#
	#print("closing door")
	##pl.play()
	#_play_sound(activation_sound)
	#animated_sprite_2d.play("activate")
#
	## Turn door collision back ON
	#set_collision_layer_value(4, true)
	#sprite.modulate.a = 1.0
	#_turn_on_light()
	#await animated_sprite_2d.animation_finished
	#
	#animated_sprite_2d.play("idle")
	#_play_sound(idle_sound)
#
#
#func _play_sound(sound: AudioStreamPlayer2D):
	## Stop all non-idle sounds before playing a new one
	#for s in [deactivation_sound, idle_sound, activation_sound]:
		#if s != sound and s.is_playing():
			#s.stop()
	#if not sound.is_playing():
		#sound.play()
		#


extends StaticBody2D

@export var door_id: String = "A"
@export var required_buttons: int = 1

var current_button_echo_id: int = -1
var pressed_count := 0
var _flicker_tween: Tween

@onready var collision = $CollisionShape2D
@onready var sprite = $Sprite2D
@onready var rune_requirement = $RuneRequirement
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var idle_sound: AudioStreamPlayer2D = $Sounds/IdleSound
@onready var activation_sound: AudioStreamPlayer2D = $Sounds/ActivationSound
@onready var deactivation_sound: AudioStreamPlayer2D = $Sounds/DeactivationSound
@onready var point_light_2d: PointLight2D = $PointLight2D

func _ready() -> void:
	_play_sound(idle_sound)
	animated_sprite_2d.play("idle")
	_turn_on_light()

func _turn_on_light() -> void:
	_stop_flicker()
	_flicker_loop()

func _turn_off_light() -> void:
	_stop_flicker()
	point_light_2d.energy = 0.0

func _flicker_loop() -> void:
	_flicker_tween = create_tween()
	_flicker_tween.tween_method(
		func(val: float): point_light_2d.energy = val,
		randf_range(1.5, 2.2),
		randf_range(0.4, 1.2),
		randf_range(0.3, 0.6)# 👈 higher = slower flicker
		
	)
	_flicker_tween.tween_callback(func(): _flicker_loop())

func _stop_flicker() -> void:
	if _flicker_tween and _flicker_tween.is_valid():
		_flicker_tween.kill()
	_flicker_tween = null

func register_button_event(id: String, pressed: bool, echo_id: int = 0):
	if id != door_id:
		return
	if pressed:
		pressed_count += 1
		current_button_echo_id = echo_id
	else:
		pressed_count -= 1
		if pressed_count == 0:
			current_button_echo_id = -1
	pressed_count = clamp(pressed_count, 0, required_buttons)
	if pressed_count >= required_buttons:
		open()
	else:
		close()

func open():
	print("opening door")
	_play_sound(deactivation_sound)
	animated_sprite_2d.play("deactivate")
	set_collision_layer_value(4, false)
	sprite.modulate.a = 0.3
	_turn_off_light()

func close():
	print("closing door")
	_play_sound(activation_sound)
	animated_sprite_2d.play("activate")
	set_collision_layer_value(4, true)
	sprite.modulate.a = 1.0
	_turn_on_light()
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("idle")
	_play_sound(idle_sound)

func _play_sound(sound: AudioStreamPlayer2D):
	for s in [deactivation_sound, idle_sound, activation_sound]:
		if s != sound and s.is_playing():
			s.stop()
	if not sound.is_playing():
		sound.play()
