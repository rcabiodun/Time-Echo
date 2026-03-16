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

@onready var entry_point = $EntryPoint
@onready var exit_point = $ExitPoint


func get_entry_position() -> Vector2:
	return entry_point.global_position


func get_exit_position() -> Vector2:
	return exit_point.global_position
