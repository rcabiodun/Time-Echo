extends Node

## Persistent save file path
const SAVE_PATH := "user://save_data.json"

## All room pools – adjust paths to your actual scenes
var tutorial_rooms: Array[PackedScene] = []
var puzzle_rooms: Array[PackedScene] = []
var hazard_rooms: Array[PackedScene] = []

## Set of room resource paths that have already been used
var used_rooms: Array = []

## Current level (1‑based)
var current_level: int = 1

## Data per completed level:
## { level_number: { "room": "res://...", "shards_collected": int, "shards_total": int } }
var level_data: Dictionary = {}

## Total Time Shards (sum of collected across all levels)
var total_shards: int = 0


func _ready():
	_load_pools()
	load_game()


func _load_pools():
	# Tutorial rooms – add all your tutorial .tscn preloads here
	tutorial_rooms = [
		preload("res://scenes/rooms/tutorials/tutorial_room_01.tscn"),
		preload("res://scenes/rooms/tutorials/tutorial_room_02.tscn"),
		#preload("res://scenes/rooms/tutorials/tutorial_room_03.tscn")
	]
	# Puzzle rooms
	puzzle_rooms = [
		preload("res://scenes/rooms/puzzle/puzzle_room_01.tscn"),
		preload("res://scenes/rooms/puzzle/puzzle_room_02.tscn"),
		preload("res://scenes/rooms/puzzle/puzzle_room_03.tscn"),
		preload("res://scenes/rooms/puzzle/puzzle_room_04.tscn"),
		preload("res://scenes/rooms/puzzle/puzzle_room_05.tscn"),
		preload("res://scenes/rooms/puzzle/puzzle_room_06.tscn"),
		 #...
	]
	# Hazard rooms
	hazard_rooms = [
		preload("res://scenes/rooms/hazard/hazard_room_01.tscn"),
		preload("res://scenes/rooms/hazard/hazard_room_02.tscn"),
		preload("res://scenes/rooms/hazard/hazard_room_03.tscn"),
		preload("res://scenes/rooms/hazard/hazard_room_04.tscn"),
		# ...
	]


## Returns the PackedScene for the given level, or null if no more rooms
#func get_room_for_level(level: int) -> PackedScene:
	#var room = _pick_next_room()
	#if room:
		## Save which room is used for this level (shards will be filled later)
		#level_data[level] = {
			#"room": room.resource_path,
			#"shards_collected": 0,
			#"shards_total": 0   # filled when room is loaded
		#}
		#used_rooms.append(room.resource_path)
		#return room
	#return null

# ============================================================
# 1. ASSIGN a room for a new level (called once)
# ============================================================
func assign_room_for_level(level: int) -> void:
	# Already assigned? Do nothing.
	if level in level_data:
		return
	
	var room = _pick_next_room()
	if room:
		level_data[level] = {
			"room": room.resource_path,
			"shards_collected": 0,
			"shards_total": 0
		}
		used_rooms.append(room.resource_path)
	else:
		print("No more rooms available!")

# ============================================================
# 2. GET the room for a level (returns the assigned scene)
# ============================================================

## Call this when the player reaches the exit (room completed)
#func complete_current_level(shards_collected: int, shards_total: int):
	#if current_level in level_data:
		#level_data[current_level]["shards_collected"] = shards_collected
		#level_data[current_level]["shards_total"] = shards_total
		#total_shards += shards_collected
	#current_level += 1
	#save_game()
func get_room_for_level(level: int) -> PackedScene:
	if not level in level_data:
		assign_room_for_level(level)   # only assigns once
	var path = level_data[level]["room"]
	return load(path)
#func complete_current_level(shards_collected: int, shards_total: int):
	## Safety: if we already have collected data, don't overwrite
	#if level_data.has(current_level) and level_data[current_level]["shards_collected"] > 0:
		#return
	#level_data[current_level]["shards_collected"] = shards_collected
	#level_data[current_level]["shards_total"] = shards_total
	#total_shards += shards_collected
	#current_level += 1
	#save_game()

## Returns an unused room following the rules:
##   Tutorials first (by difficulty 1→3)
##   Then puzzles + hazards (by difficulty 1→3, random unvisited)
func _pick_next_room() -> PackedScene:
	# 1. Any unused tutorial rooms?
	for room in _get_unused_sorted_by_difficulty(tutorial_rooms):
		return room
	# 2. Otherwise, combined puzzle + hazard, sorted by difficulty
	var combined = puzzle_rooms + hazard_rooms
	for room in _get_unused_sorted_by_difficulty(combined):
		return room
	return null


## Helper: returns unused scenes from the array, sorted by difficulty (1→3)
func _get_unused_sorted_by_difficulty(pool: Array) -> Array:
	var unused: Array = []
	for scene in pool:
		if not scene.resource_path in used_rooms:
			# Need to read difficulty – instantiate temporarily
			var temp = scene.instantiate()
			var diff = temp.difficulty
			unused.append({ "scene": scene, "difficulty": diff })
			temp.queue_free()
	
	unused.sort_custom(func(a, b): return a.difficulty < b.difficulty)
	var scenes: Array = []
	for item in unused:
		scenes.append(item.scene)
	return scenes


## ---------- Persistence ----------
func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"current_level": current_level,
			"used_rooms": used_rooms,
			"level_data": level_data,
			"total_shards": total_shards
		}
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


#func load_game():
	#if not FileAccess.file_exists(SAVE_PATH):
		#return   # first play, use defaults
	#
	#var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	#if file:
		#var json = JSON.new()
		#var error = json.parse(file.get_as_text())
		#if error == OK:
			#var data = json.data
			#current_level = data.get("current_level", 1)
			#used_rooms = data.get("used_rooms", [])
			#level_data = data.get("level_data", {})
			#total_shards = data.get("total_shards", 0)
		#file.close()

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			current_level = data.get("current_level", 1)
			used_rooms = data.get("used_rooms", [])

			# Load and convert keys to int
			var raw_data = data.get("level_data", {})
			level_data.clear()
			for key in raw_data.keys():
				level_data[int(key)] = raw_data[key]

			total_shards = data.get("total_shards", 0)
		file.close()

## Returns level_data for UI (Level Select)
func get_level_data() -> Dictionary:
	return level_data



func complete_current_level(shards_collected: int, shards_total: int) -> void:
	if current_level in level_data and level_data[current_level]["shards_collected"] > 0:
		return   # already completed, ignore (safety for retry -> next)
	
	level_data[current_level]["shards_collected"] = shards_collected
	level_data[current_level]["shards_total"] = shards_total
	total_shards += shards_collected
	current_level += 1
	save_game()
	

func get_room_path_for_level(level: int) -> String:
	# this function is so any level’s room scene can be loaded directly without changing current_level
	if level_data.has(level):
		return level_data[level]["room"]
	return ""

# Updates shards for a specific level (replay improvement).
# Only overwrites if the new count is higher; does NOT change current_level.
func update_level_shards(level: int, collected: int, total: int) -> void:
	print("updating ;level shardsx")
	
	if not level_data.has(level):
		return
	
	print("dad")
	

	var old = level_data[level]["shards_collected"]
	if collected > old:
		# Add only the difference to total_shards
		total_shards += (collected - old)
		level_data[level]["shards_collected"] = collected
		level_data[level]["shards_total"] = total
		save_game()
