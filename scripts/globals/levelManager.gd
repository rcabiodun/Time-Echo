extends Node2D

## ==============================
## UI / Effects
## ==============================
@onready var canvas_modulate: CanvasModulate = $"../CanvasModulate"
var canvas_tween: Tween

@onready var distortion_rect = $"../CanvasLayer/ColorRect"
var distortion_tween: Tween
var was_recording := false

## ==============================
## Echo System
## ==============================
var next_echo_id: int = 1
@onready var EchoScene = preload("res://scenes/characters/echo.tscn")
@onready var player: CharacterBody2D = $"../Player"

## ==============================
## Progression / Room Management
## ==============================
var current_room_instance: Node = null
var current_room_scene: PackedScene

var shards_collected_this_room: int = 0
var total_shards_this_room: int = 0

# Prevent double‑trigger of room change
var is_changing_room := false

# Level Complete screen
var level_complete_screen: PackedScene = preload("res://scenes/ui/level_complete_screen.tscn")
var is_level_complete := false

## ==============================
## Unused old variables (kept for compatibility but no longer used)
## ==============================
var debug_overlay
var current_room_index := 0
var generated_rooms: Array[PackedScene] = []
var current_difficulty := 1
var player_echo_capacity := 0
var rune_count := 0
var last_room_type = null
var same_type_count = 0
var is_replay := false
var replay_level: int = -1   # only set when replaying
var is_changing_scene := false


func _ready() -> void:
	Global.apply_lighting_setting()
	if Global.selected_level != -1:
		# We came from the Level Select screen
		if Global.replay_mode:
			# Replaying an already completed level
			is_replay = true
			replay_level = Global.selected_level
			var room_path = GameProgression.get_room_path_for_level(replay_level)
			current_room_scene = load(room_path) if room_path != "" else null
		else:
			# First‑time play of the CURRENT level (the one that is ready to be played)
			is_replay = false
			replay_level = -1
			current_room_scene = GameProgression.get_room_for_level(Global.selected_level)

		Global.selected_level = -1
	else:
		# Normal game start or continuing from a previous session
		is_replay = false
		replay_level = -1
		current_room_scene = GameProgression.get_room_for_level(GameProgression.current_level)

	if current_room_scene:
		load_room(current_room_scene)
	else:
		print("No room to load!")
		
		
# =========================
# Button / Door / InvisibleFloor
# =========================
func _on_button_state_changed(attached_items_ids: Dictionary, pressed: bool, echo_id: int = 0) -> void:
	if is_changing_scene:
		return
	for door in get_tree().get_nodes_in_group("doors"):
		door.register_button_event(attached_items_ids["door_id"], pressed, echo_id)

	for invisible_floor in get_tree().get_nodes_in_group("invisible_floor"):
		invisible_floor.register_button_event(attached_items_ids["invisible_floor_id"], pressed, echo_id)


func _on_projectile_receiver_activation(elevator_id: String) -> void:
	if is_changing_scene:
		return
	print("received elevator project signal by level manager")
	for elevator in get_tree().get_nodes_in_group("elevators"):
		elevator.register_receiver_activation_event(elevator_id)


# =========================
# Time Shard Collection
# =========================
func _on_time_shard_collected() -> void:
	print("Time shard collected")
	shards_collected_this_room += 1


# =========================
# Distortion & Darken Effects
# =========================
func _process(delta: float) -> void:
	print(Global.environment_lighting_enabled)
	# Block input if the level complete screen is showing
	if is_level_complete:
		return

	if Global.is_recording != was_recording:
		was_recording = Global.is_recording
		if was_recording:
			activate_distortion()
		else:
			deactivate_distortion()

	if Global.is_recording:
		darken_scene()
	else:
		restore_scene()


func darken_scene() -> void:
	if canvas_tween:
		canvas_tween.kill()
	# Uncomment to re‑enable darken:
	# canvas_tween = create_tween()
	# canvas_tween.tween_property(canvas_modulate, "color", Color(0.4, 0.4, 0.5, 1), 0.8)


func restore_scene() -> void:
	if canvas_tween:
		canvas_tween.kill()
	# canvas_tween = create_tween()
	# canvas_tween.tween_property(canvas_modulate, "color", Color(1, 1, 1, 1), 0.8)


func activate_distortion() -> void:
	if distortion_tween:
		distortion_tween.kill()
	distortion_tween = create_tween()
	distortion_tween.tween_property(
		distortion_rect.material,
		"shader_parameter/opacity",
		0.1,
		1
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func deactivate_distortion() -> void:
	if distortion_tween:
		distortion_tween.kill()
	distortion_tween = create_tween()
	distortion_tween.tween_property(
		distortion_rect.material,
		"shader_parameter/opacity",
		0.0,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# =========================
# =========================
# Echo Creation
func _on_player_create_echo(frames: Array) -> void:
	var active_echo_ids: Array[int] = []
	for echo in $"../Echoes".get_children():
		if echo.get("echo_id") != null:
			active_echo_ids.append(echo.echo_id)

	# Reset resettable objects for this echo
	for obj in get_tree().get_nodes_in_group("resettable"):
		obj.reset_if_needed(active_echo_ids)

	# Reset runes for this echo
	for rune in get_tree().get_nodes_in_group("runes"):
		rune.reset_rune_if_needed(active_echo_ids)

	var echo = preload("res://scenes/characters/echo.tscn").instantiate()
	$"../Echoes".add_child(echo)

	echo.set_echo_id(next_echo_id)
	next_echo_id += 1
	echo.start_playback(frames)


# =========================
# Room Transition (exit reached)
# =========================
#func request_room_change(exit_direction) -> void:
	#
	#if is_changing_room or is_level_complete:
		#return
	#is_changing_room = true
	#is_level_complete = true
#
	## Store current values before showing screen
	#var current_lvl = GameProgression.current_level
	#var shards = shards_collected_this_room
	#var total = total_shards_this_room
#
	## Show Level Complete screen
	#var screen = level_complete_screen.instantiate()
	##add_child(screen)
	#get_parent().add_child(screen)
	#screen.show_results(shards, total, current_lvl)
#
	## Connect signals
	#screen.retry_pressed.connect(_on_retry_level.bind(screen))
	#screen.next_pressed.connect(_on_next_level.bind(screen))

#func request_room_change(exit_direction) -> void:
	#if is_changing_room or is_level_complete:
		#return
	#is_changing_room = true
	#is_level_complete = true
#
	#var current_lvl = GameProgression.current_level
	#var shards = shards_collected_this_room
	#var total = total_shards_this_room
#
	#var screen = level_complete_screen.instantiate()
	#get_parent().add_child(screen)
#
	#if is_replay:
		## In replay mode: show Retry / Menu
		#screen.show_results_for_replay(shards, total, current_lvl)
		#screen.retry_pressed.connect(_on_retry_level.bind(screen))
		#screen.menu_pressed.connect(_on_menu_from_replay.bind(screen))
	#else:
		## Normal mode: show Retry / Next
		#screen.show_results(shards, total, current_lvl)
		#screen.retry_pressed.connect(_on_retry_level.bind(screen))
		#screen.next_pressed.connect(_on_next_level.bind(screen))
#

func request_room_change(exit_direction) -> void:
	if is_changing_room or is_level_complete:
		return
	is_changing_room = true
	is_level_complete = true

	var current_lvl = replay_level if is_replay else GameProgression.current_level
	var shards = shards_collected_this_room
	var total = total_shards_this_room

	var screen = level_complete_screen.instantiate()
	get_parent().add_child(screen)

	if is_replay:
		screen.show_results_for_replay(shards, total, current_lvl)
		screen.retry_pressed.connect(_on_retry_level.bind(screen))
		screen.menu_pressed.connect(_on_menu_from_replay.bind(screen))
	else:
		screen.show_results(shards, total, current_lvl)
		screen.retry_pressed.connect(_on_retry_level.bind(screen))
		screen.next_pressed.connect(_on_next_level.bind(screen))
func _on_retry_level(screen: CanvasLayer) -> void:
	screen.queue_free()
	is_level_complete = false
	is_changing_room = false

	# Reload same room (shards reset inside load_room)
	load_room(current_room_scene)
	


func _on_next_level(screen: CanvasLayer) -> void:
	screen.queue_free()

	# 1. Commit completion (increments current_level, saves data)
	GameProgression.complete_current_level(shards_collected_this_room, total_shards_this_room)

	# 2. Get room for the NEW current level
	var next_scene = GameProgression.get_room_for_level(GameProgression.current_level)
	if next_scene:
		# Clean echoes before transition
		for echo in $"../Echoes".get_children():
			echo.queue_free()

		DeathManager.trigger_room_transition(func():
			await load_room(next_scene)
		)
		
		
	else:
		print("You beat the game! – Load win screen or return to menu")

	is_level_complete = false
	is_changing_room = false


# =========================
# Load a Room (called on first load, death, retry, next)
# =========================
func load_room(room_scene: PackedScene) -> void:
	# Remove previous room
	
	
	#$"../Player".enable_controls_ui()
	if current_room_instance:
		current_room_instance.queue_free()

	# Ensure echoes are cleaned up
	for echo in $"../Echoes".get_children():
		echo.queue_free()

	# Instantiate new room
	current_room_instance = room_scene.instantiate()
	$"../Rooms".add_child(current_room_instance)

	await get_tree().process_frame
	
	# Place player at room entry
	var entry_pos = current_room_instance.get_entry_position()
	$"../Player".global_position = entry_pos

	await get_tree().process_frame
	Global.apply_lighting_setting()
	# Update shard counts for this room
	total_shards_this_room = current_room_instance.time_shard_count
	shards_collected_this_room = 0

	# Revive player (in case they were dead)
	$"../Player".revive()
	
	# Connect signals safely – avoid duplicates
	for button in get_tree().get_nodes_in_group("buttons"):
		if not button.is_connected("button_state_changed", _on_button_state_changed):
			button.connect("button_state_changed", _on_button_state_changed)

	for timeshard in get_tree().get_nodes_in_group("time_shards"):
		if not timeshard.is_connected("time_shard_collected", _on_time_shard_collected):
			timeshard.connect("time_shard_collected", _on_time_shard_collected)

	for project_receiver in get_tree().get_nodes_in_group("projectile_receiver"):
		if not project_receiver.is_connected("projectile_receiver_activated", _on_projectile_receiver_activation):
			project_receiver.connect("projectile_receiver_activated", _on_projectile_receiver_activation)

	# Reset the changing flag after everything is ready
	is_changing_room = false


#func _on_menu_from_replay(screen: CanvasLayer) -> void:
	#screen.queue_free()
#
	## Attempt to improve the level's shard score if better
	#GameProgression.update_level_shards(
		#GameProgression.current_level,   # The level we just replayed
		#shards_collected_this_room,
		#total_shards_this_room
	#)
#
	#is_changing_scene = true
	#_disconnect_all_signals()
	#get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
	#
	#get_tree().change_scene_to_file("res://scenes/level_select.tscn")
func _on_menu_from_replay(screen: CanvasLayer) -> void:
	screen.queue_free()

	# Save better shard score for the replayed level (not the current progression level)
	GameProgression.update_level_shards(
		replay_level,   # <-- fixed
		shards_collected_this_room,
		total_shards_this_room
	)

	is_changing_scene = true
	_disconnect_all_signals()
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
func _disconnect_all_signals() -> void:
	for button in get_tree().get_nodes_in_group("buttons"):
		if button.is_connected("button_state_changed", _on_button_state_changed):
			button.disconnect("button_state_changed", _on_button_state_changed)
	for timeshard in get_tree().get_nodes_in_group("time_shards"):
		if timeshard.is_connected("time_shard_collected", _on_time_shard_collected):
			timeshard.disconnect("time_shard_collected", _on_time_shard_collected)
	for project_receiver in get_tree().get_nodes_in_group("projectile_receiver"):
		if project_receiver.is_connected("projectile_receiver_activated", _on_projectile_receiver_activation):
			project_receiver.disconnect("projectile_receiver_activated", _on_projectile_receiver_activation)
