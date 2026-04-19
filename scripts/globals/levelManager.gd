extends Node2D

@onready var canvas_modulate: CanvasModulate = $"../CanvasModulate"#this darken scene while recording
var canvas_tween : Tween

# ✅ Distortion Shader
@onready var distortion_rect = $"../CanvasLayer/ColorRect"
var distortion_tween : Tween
var was_recording := false

# Preload Echo scene
@onready var EchoScene = preload("res://scenes/characters/echo.tscn")
var next_echo_id: int = 1

var debug_overlay
var current_room_index := 0
var generated_rooms : Array[PackedScene] = []
var current_room_instance : Node = null



var start_rooms : Array[PackedScene] = []
var puzzle_rooms : Array[PackedScene] = []
var hazard_rooms : Array[PackedScene] = []
#var transition_rooms : Array[PackedScene] = []
var final_rooms : Array[PackedScene] = []

var current_difficulty := 1
var player_echo_capacity := 0
var rune_count := 0
var last_room_type = null
var same_type_count = 0


#player_echo_capacity = "what the generator THINKS the player can handle"
func _ready():
	#var debug_overlay
	debug_overlay = get_tree().get_first_node_in_group("debug_overlay")
	
	if debug_overlay:
		print("Debuf overlay found")
	else:
		print("Debug overlay not found")
	# Connect every button in the level to the level manager
	
	#commented out for testing levels one by one
	generated_rooms=[
		
		
		preload("res://scenes/rooms/puzzle/puzzle_room_01.tscn"),
		
		
		preload("res://scenes/rooms/puzzle/puzzle_room_02.tscn")
	]
	#load_room_pools()
	#generate_level()

	current_room_index = 0
	load_room(generated_rooms[0])
	#if debug_overlay:
#
		#print(debug_overlay.stats_label.text)
		#print(debug_overlay.rooms_label.text)
		#print(debug_overlay.log_label.text)

# When ANY button changes, notify all doors
func _on_button_state_changed(attached_items_ids: Dictionary, pressed: bool, echo_id: int = 0):
	for door in get_tree().get_nodes_in_group("doors"):
		door.register_button_event(attached_items_ids["door_id"], pressed, echo_id)
	
	for invisible_floor in get_tree().get_nodes_in_group("invisible_floor"):
		invisible_floor.register_button_event(attached_items_ids["invisible_floor_id"], pressed, echo_id) 

# When ANY button changes, notify all doors
func _on_projectile_receiver_activation(elevator_id: String):
	print("receibed elevator project signal by level manager")
	for elevator in get_tree().get_nodes_in_group("elevators"):
		elevator.register_receiver_activation_event(elevator_id)

# Called every frame
func _process(delta):
	# Handle distortion activation only when state changes
	if Global.is_recording != was_recording:
		was_recording = Global.is_recording
		
		if was_recording:
			activate_distortion()
		else:
			deactivate_distortion()

	# Keep your existing darken effect
	if Global.is_recording:
		darken_scene()
	else:
		restore_scene()




# =========================
# 🎨 Darken Scene
# =========================
func darken_scene():
	if canvas_tween:
		canvas_tween.kill()
	
	#canvas_tween = create_tween()
	#canvas_tween.tween_property(
		#canvas_modulate,
		#"color",
		#Color(0.4, 0.4, 0.5, 1),
		#0.8
	#)


func restore_scene():
	if canvas_tween:
		canvas_tween.kill()
	
	#canvas_tween = create_tween()
	#canvas_tween.tween_property(
		#canvas_modulate,
		#"color",
		#Color(1, 1, 1, 1),
		#0.8
	#)


# =========================
# 🌊 Distortion Animation
# =========================
func activate_distortion():
	if distortion_tween:
		distortion_tween.kill()
	
	distortion_tween = create_tween()
	distortion_tween.tween_property(
		distortion_rect.material,
		"shader_parameter/strength",
		0.6,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func deactivate_distortion():
	if distortion_tween:
		distortion_tween.kill()
	
	distortion_tween = create_tween()
	distortion_tween.tween_property(
		distortion_rect.material,
		"shader_parameter/strength",
		0.0,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# =========================
# 👻 Echo Creation
# =========================
func _on_player_create_echo(frames: Array) -> void:

	var active_echo_ids: Array[int] = []
	
	#for echo in $Echoes.get_children():
	for echo in $"../Echoes".get_children():
		if echo.get("echo_id") != null:
			active_echo_ids.append(echo.echo_id)

	for obj in get_tree().get_nodes_in_group("resettable"):
		obj.reset_if_needed(active_echo_ids)

	for rune in get_tree().get_nodes_in_group("runes"):
		rune.reset_rune_if_needed(active_echo_ids)

	var echo = preload("res://scenes/characters/echo.tscn").instantiate()
	print("")
	$"../Echoes".add_child(echo)

	echo.set_echo_id(next_echo_id)
	next_echo_id += 1

	echo.start_playback(frames)
	

# =========================
# 🏘️ Room Management
# =========================


func request_room_change(exit_direction):
	
	current_room_index += 1

	if current_room_index >= generated_rooms.size():
		print("Level Complete!")
		return

	var next_room = generated_rooms[current_room_index]
	
	# 👇 pass load_room as a callback
	for echo in $"../Echoes".get_children():
		echo.queue_free()
	DeathManager.trigger_room_transition(func():
		await load_room(next_room)
	)
#
#func load_room(room_scene: PackedScene):
	##DeathManager.trigger_room_transition_fade()
	## Remove the current room if it exists
	#if current_room_instance:
		#current_room_instance.queue_free()
#
	## Create and add the new room to the scene
	#current_room_instance = room_scene.instantiate()
	#$"../Rooms".add_child(current_room_instance)
#
	## Wait one frame so the room fully initializes (_ready runs, onready vars are valid)
	#await get_tree().process_frame 
#
	## Get the entry position from the new room and place the player there
	#var entry_pos = current_room_instance.get_entry_position()
	#$"../Player".global_position = entry_pos
#
	## (Optional) Camera limits can be set here per room
	#for button in get_tree().get_nodes_in_group("buttons"):
		#button.connect("button_state_changed", _on_button_state_changed)
		##button.connect("button_state_changed", _on_button_state_changed)
		##button.connect("button")
	#
	#for project_receiver in get_tree().get_nodes_in_group("projectile_receiver"):
		#print("found 123")
		#project_receiver.connect("projectile_receiver_activated", _on_projectile_receiver_activation)
	#
	#
	#

func load_room(room_scene: PackedScene):
	if current_room_instance:
		current_room_instance.queue_free()

	current_room_instance = room_scene.instantiate()
	$"../Rooms".add_child(current_room_instance)
	
	await get_tree().process_frame

	var entry_pos = current_room_instance.get_entry_position()
	$"../Player".global_position = entry_pos

	# ✅ Wait one more frame AFTER placing the player so any
	# overlapping portal signals fire and are ignored before we revive
	await get_tree().process_frame
	$"../Player".revive()

	for button in get_tree().get_nodes_in_group("buttons"):
		button.connect("button_state_changed", _on_button_state_changed)
	for project_receiver in get_tree().get_nodes_in_group("projectile_receiver"):
		print("found 123")
		project_receiver.connect("projectile_receiver_activated", _on_projectile_receiver_activation)	

func load_room_pools():

	# Define all available room pools grouped by type

	start_rooms = [
		preload("res://scenes/rooms/start/start_room_02.tscn")
	]

	puzzle_rooms = [
		preload("res://scenes/rooms/puzzle/puzzle_room_01.tscn"),
		preload("res://scenes/rooms/puzzle/puzzle_room_02.tscn")
	]

	hazard_rooms = [
		preload("res://scenes/rooms/hazard/spikes_room_01.tscn")
	]

	#transition_rooms = [
		##preload("res://scenes/rooms/transition/corridor_room.tscn")
		#preload("res://scenes/rooms/hazard/spikes_room_01.tscn")
	#]

	final_rooms = [
		preload("res://scenes/rooms/final/exit_room.tscn")
	]


func generate_level():

	# Clear any previously generated layout
	generated_rooms.clear()
	
	# 1️⃣ Pick a random start room
	var start = start_rooms.pick_random()
	generated_rooms.append(start)

	# Track the exit direction of the current room
	var current_exit = get_room_exit_direction(start)

	# 2️⃣ Generate middle rooms
	for i in range(4): # number of rooms

		# Find a room whose entry matches the required direction
		var next_room = get_valid_room(current_exit)

		if next_room:
			generated_rooms.append(next_room)

			# Update current exit direction for next iteration
			current_exit = get_room_exit_direction(next_room)

	# 3️⃣ Add a final room at the end
	var final = final_rooms.pick_random()
	
	generated_rooms.append(final)
	
	if debug_overlay:
		var names = []
		for room in generated_rooms:
			names.append(room.resource_path.get_file())
		debug_overlay.update_rooms(names)
	

func get_room_exit_direction(room_scene: PackedScene):

	# Temporarily instantiate the room to read its exit direction
	var temp = room_scene.instantiate()
	var dir = temp.exit_direction

	# Clean up immediately after reading
	temp.queue_free()

	return dir
	

func get_opposite(dir):

	# Returns the opposite direction for connection matching
	match dir:
		BaseRoom.Direction.LEFT: return BaseRoom.Direction.RIGHT
		BaseRoom.Direction.RIGHT: return BaseRoom.Direction.LEFT
		BaseRoom.Direction.UP: return BaseRoom.Direction.DOWN
		BaseRoom.Direction.DOWN: return BaseRoom.Direction.UP


#func get_valid_room(required_entry_direction):
#
	## Combine all possible non-start/non-final rooms
	#var all_rooms = puzzle_rooms + hazard_rooms + transition_rooms
#
	## Shuffle to ensure randomness
	#all_rooms.shuffle()
#
	## Find a room whose entry matches the required direction
	#for room_scene in all_rooms:
#
		#var temp = room_scene.instantiate()
#
		## Check if this room can connect properly
		#if temp.entry_direction == get_opposite(required_entry_direction):
			#temp.queue_free()
			#return room_scene
#
		#temp.queue_free()
#
	## If no valid room is found, return null (should be handled safely)
	#return null

func get_valid_room(required_entry_direction):

	# Combine all candidate room pools
	var all_rooms = puzzle_rooms + hazard_rooms 

	# Shuffle for randomness so we don’t always pick the same rooms
	all_rooms.shuffle()

	for room_scene in all_rooms:

		# Instantiate temporarily to inspect its properties
		var temp = room_scene.instantiate()

		# =========================
		# 1️⃣ Direction Check
		# Ensure the room connects properly with the previous room
		# =========================
		if temp.entry_direction != get_opposite(required_entry_direction):
			if debug_overlay:
				debug_overlay.add_log("❌ Reject: Direction mismatch → " + temp.name)

			temp.queue_free()
			continue

		# =========================
		# 2️⃣ Difficulty Check
		# Prevent sudden spikes in difficulty
		# Allow only gradual increase (+1 at most)
		# =========================
		if temp.difficulty > current_difficulty + 1:
			if debug_overlay:
				#debug_overlay.add_log("❌ Reject: room difficulty us greater that current difficulty + 1 → " + temp.name)
				debug_overlay.add_log(
				    "❌ Reject: room difficulty,{room_difficulty}, is greater than current difficulty,{current_difficulty}, + 1 → {room}"
					.format({"room": temp.name,"room_difficulty":temp.difficulty,"current_difficulty":current_difficulty})
				)
			temp.queue_free()
			continue

		# =========================
		# 3️⃣ Echo Requirement Check
		# Ensure the player has enough echoes to solve the room
		# =========================
		if temp.requires_echoes > player_echo_capacity:
			if debug_overlay:
				debug_overlay.add_log("❌ Reject: Needs more echoes → " + temp.name)
			temp.queue_free()
			continue

		## =========================
		## 4️⃣ Rune Progression Check
		## Prevent too many rooms with no progression (dead rooms)
		## =========================
		#if not temp.provides_rune and rune_count == 0:
			#temp.queue_free()
			#continue

		# =========================
		# 5️⃣ Variety Check (Room Repetition Control)
		# Prevent too many rooms of the same type in a row
		# =========================
		if temp.room_type == last_room_type:
			same_type_count += 1
		else:
			same_type_count = 0

		# If we already used this type too many times, skip it
		if same_type_count >= 2:
			if debug_overlay:
				#debug_overlay.add_log("❌ Reject: Needs more echoes → " + temp.name)
				debug_overlay.add_log("❌ Reject: Too repetitive → " + temp.name)
			temp.queue_free()
			continue

		# =========================
		# 6️⃣ Safety Room Check
		# If difficulty is high, force a safe/breathing room
		# =========================
		#if current_difficulty >= 3 and not temp.is_safe_room:
			#temp.queue_free()
			#continue

		# =========================
		# ✅ VALID ROOM FOUND
		# =========================

		# Update progression systems (difficulty, echoes, runes)
		update_progression(temp)

		# Track last room type for repetition control
		last_room_type = temp.room_type

		temp.queue_free()
		if debug_overlay:
			debug_overlay.add_log("✅ Accepted: " + temp.name)
		return room_scene

	# If no valid room is found, return null (should be handled safely by caller)
	return null
	
	
func update_progression(room):

	# Increase difficulty slowly
	current_difficulty = clamp(current_difficulty + 1, 1, 3)
	if debug_overlay:
		debug_overlay.update_stats(current_difficulty, player_echo_capacity, rune_count)
	# Track rune progression
	#if room.provides_rune:
		#rune_count += 1

	# Increase echo capacity over time
	# "At this point in the level, what should the player be capable of?"
	player_echo_capacity = min(player_echo_capacity + 1, 3)
