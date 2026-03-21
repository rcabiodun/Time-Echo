extends Node2D

class_name BaseRoom

enum RoomType {
	START,
	PUZZLE,
	HAZARD,
	FINAL,
	TRANSITION
}

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

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

func get_entry_position() -> Vector2:
	print("Getting entry position of room : "+ self.name)
	
	return entry_point.global_position


func get_exit_position() -> Vector2:
	return exit_point.global_position


func _ready() -> void:
	print("This is the room you are in : "+ self.name)
	#print("This is the entry point:" )
	#print(entry_point.global_position)
	#print("This is the exit point:" )
	#print(exit_point.global_position)

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("body Entered")
	if body.is_in_group("player"):
		print("Player jusy hit the exit")
		var level_manager = get_tree().get_first_node_in_group("level_manager")
		#level_manager.request_room_change(exit_direction)
		level_manager.call_deferred("request_room_change", exit_direction)
	

	
