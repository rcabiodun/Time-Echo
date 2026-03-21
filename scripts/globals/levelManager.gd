extends Node2D

@onready var canvas_modulate: CanvasModulate = $"../CanvasModulate"
var canvas_tween : Tween

# ✅ Distortion Shader
@onready var distortion_rect = $"../CanvasLayer/ColorRect"
var distortion_tween : Tween
var was_recording := false

# Preload Echo scene
@onready var EchoScene = preload("res://scenes/characters/echo.tscn")
var next_echo_id: int = 1


var current_room_index := 0
var generated_rooms : Array[PackedScene] = []
var current_room_instance : Node = null



var start_rooms : Array[PackedScene] = []
var puzzle_rooms : Array[PackedScene] = []
var hazard_rooms : Array[PackedScene] = []
var transition_rooms : Array[PackedScene] = []
var final_rooms : Array[PackedScene] = []


func _ready():
	# Connect every button in the level to the level manager
	for button in get_tree().get_nodes_in_group("buttons"):
		button.connect("button_state_changed", _on_button_state_changed)
	load_room_pools()
	generate_level()

	current_room_index = 0
	load_room(generated_rooms[0])

# When ANY button changes, notify all doors
func _on_button_state_changed(door_id: String, pressed: bool, echo_id: int = 0):
	for door in get_tree().get_nodes_in_group("doors"):
		door.register_button_event(door_id, pressed, echo_id)


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
	
	canvas_tween = create_tween()
	canvas_tween.tween_property(
		canvas_modulate,
		"color",
		Color(0.4, 0.4, 0.5, 1),
		0.8
	)


func restore_scene():
	if canvas_tween:
		canvas_tween.kill()
	
	canvas_tween = create_tween()
	canvas_tween.tween_property(
		canvas_modulate,
		"color",
		Color(1, 1, 1, 1),
		0.8
	)


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

func load_room(room_scene: PackedScene):
	#DeathManager.trigger_room_transition_fade()
	# Remove the current room if it exists
	if current_room_instance:
		current_room_instance.queue_free()

	# Create and add the new room to the scene
	current_room_instance = room_scene.instantiate()
	$"../Rooms".add_child(current_room_instance)

	# Wait one frame so the room fully initializes (_ready runs, onready vars are valid)
	await get_tree().process_frame 

	# Get the entry position from the new room and place the player there
	var entry_pos = current_room_instance.get_entry_position()
	$"../Player".global_position = entry_pos

	# (Optional) Camera limits can be set here per room


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

	transition_rooms = [
		preload("res://scenes/rooms/transition/corridor_room.tscn")
	]

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


func get_valid_room(required_entry_direction):

	# Combine all possible non-start/non-final rooms
	var all_rooms = puzzle_rooms + hazard_rooms + transition_rooms

	# Shuffle to ensure randomness
	all_rooms.shuffle()

	# Find a room whose entry matches the required direction
	for room_scene in all_rooms:

		var temp = room_scene.instantiate()

		# Check if this room can connect properly
		if temp.entry_direction == get_opposite(required_entry_direction):
			temp.queue_free()
			return room_scene

		temp.queue_free()

	# If no valid room is found, return null (should be handled safely)
	return null
