extends Node2D

class_name BaseRoom

enum RoomType {
	TUTORIAL,
	START,
	PUZZLE,
	HAZARD,
	FINAL,
	
}

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}
#@export var teleport_sound: AudioStreamPlayer2D
@onready var teleport_sound: AudioStreamPlayer2D = $Sounds/TeleportSound
var exit_delay_active := true
@export var difficulty : int = 1   # 1 = easy, 2 = medium, 3 = hard
@export var requires_echoes : int = 0
#@export var provides_rune : bool = false
@export var is_safe_room : bool = false

#difficulty        → how hard the room is
#requires_echoes   → minimum echoes needed to solve it
#provides_rune     → gives progression
#is_safe_room      → no hazards (breathing space)
#requires_echoes = "minimum needed to solve the room"

@export var room_type : RoomType
@export var entry_direction : Direction
@export var exit_direction : Direction
#
##@onready var entry_point = $EntryPoint
#@onready var exit_point = $ExitPoint
#@onready var entry_point: Marker2D = $EntryPoint
@export var entry_path : NodePath
@export var exit_path : NodePath

@onready var entry_point: Marker2D = get_node(entry_path)
@onready var exit_point: Marker2D = get_node(exit_path)
@onready var exit_animated_sprite_2d: AnimatedSprite2D = $Exit/AnimatedSprite2D
@onready var entry_animated_sprite_2d: AnimatedSprite2D = $Entry/AnimatedSprite2D
@onready var entry_point_light_2d: PointLight2D = $Entry/PointLight2D
@onready var exit_point_light_2d: PointLight2D = $Exit/PointLight2D
@onready var gameplay_objects: Node2D = $GameplayObjects
@onready var time_shard_count = 0
var _entry_flicker_tween: Tween
var _exit_flicker_tween: Tween
var is_transitioning = false

func get_entry_position() -> Vector2:
	print("Getting entry position of room : "+ self.name)
	return entry_point.global_position

func get_exit_position() -> Vector2:
	return exit_point.global_position

func _ready() -> void:
	#var count = 0
	
	for child in gameplay_objects.get_children():
		if child.is_in_group("time_shards"): # replace with your script/class name
			time_shard_count += 1

	Input.vibrate_handheld(800)  # vibrate for 200 milliseconds
	print("This is the room you are in : " + self.name)
	_turn_off_light(exit_point_light_2d, false)
	teleport_sound.play()
	exit_animated_sprite_2d.play("idle")
	entry_animated_sprite_2d.z_index = 1
	_turn_on_light(entry_point_light_2d, true)  # flicker ON while animation plays
	entry_animated_sprite_2d.play_backwards("activate")
	await entry_animated_sprite_2d.animation_finished
	entry_animated_sprite_2d.z_index = 0
	_turn_off_light(entry_point_light_2d, true)  # flicker OFF after animation
	await get_tree().create_timer(0.3).timeout
	exit_delay_active = false

func room_change(body:Node2D):
	print("Player jusy hit the exit")
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	#level_manager.request_room_change(exit_direction)
	level_manager.call_deferred("request_room_change", exit_direction)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if exit_delay_active or is_transitioning:
		return
	if body.is_in_group("player"):
		Input.vibrate_handheld(800)  # vibrate for 200 milliseconds
		is_transitioning = true
		teleport_sound.play()
		_turn_on_light(exit_point_light_2d, false)  # exit flickers on
		exit_animated_sprite_2d.z_index = 1
		exit_animated_sprite_2d.play("activate")
		body._play_die_animation()
		await exit_animated_sprite_2d.animation_finished
		room_change(body)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_transitioning = false  # 🔓 Unlock when player leaves (safety reset)

func _turn_on_light(point_light: PointLight2D, is_entry: bool) -> void:
	_start_flicker(point_light, is_entry)

func _turn_off_light(point_light: PointLight2D, is_entry: bool) -> void:
	if is_entry:
		_stop_flicker(_entry_flicker_tween)
	else:
		_stop_flicker(_exit_flicker_tween)
	point_light.energy = 0.0

func _start_flicker(point_light: PointLight2D, is_entry: bool) -> void:
	if is_entry:
		_stop_flicker(_entry_flicker_tween)
	else:
		_stop_flicker(_exit_flicker_tween)
	_flicker_loop(point_light, is_entry)
	
func _flicker_loop(point_light: PointLight2D, is_entry: bool) -> void:
	var tween = create_tween()
	tween.tween_method(
		func(val: float): point_light.energy = val,
		randf_range(1.2, 1.8),#max brightness
		randf_range(0.4, 1.2),
		randf_range(0.08 , 0.2)
	)
	tween.tween_callback(func(): _flicker_loop(point_light, is_entry))
	if is_entry:
		_entry_flicker_tween = tween
	else:
		_exit_flicker_tween = tween
func _stop_flicker(tween: Tween) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = null
