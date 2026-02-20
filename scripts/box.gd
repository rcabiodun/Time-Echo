#extends CharacterBody2D
#
## ===============================
## 🧠 TIME STATE MEMORY
## ===============================
#var start_position: Vector2                 # Original spawn position
#var timeline_position: Vector2              # Last valid echo-created position
#var influencing_echo_ids: Array[int] = []   # Echoes that influenced this box
#
## When true, box is frozen horizontally at its timeline X
#var locked_to_timeline := false
#
## ===============================
## 📦 CARRY SYSTEM
## ===============================
#var being_carried := false
#var carrier: Node2D = null
#
## ===============================
## 🌍 GRAVITY
## ===============================
#const GRAVITY := 900.0
#
#func _ready():
	#start_position = global_position
	#timeline_position = global_position
	#add_to_group("carryable")
	#add_to_group("resettable")
#
## ===============================
## 🔄 PHYSICS LOOP
## ===============================
#var reset_timer_started := false
#
#func _physics_process(delta):
	## Horizontal timeline lock when needed
	#if locked_to_timeline and not being_carried:
		#if not reset_timer_started:
			#$ResetTimer.start()
			#reset_timer_started = true
#
	#else:
		## Reset the flag when lock is gone
		#reset_timer_started = false
#
	## Normal gravity when not carried
	#if not being_carried:
		#if not Global.is_recording:
			#set_collision_layer_value(1, true)
		#if not is_on_floor():
			#velocity.y += GRAVITY * delta
		#else:
			#velocity.y = 0
#
	#move_and_slide()
 ## Godot 4: no arguments needed
#
## ===============================
## ✋ PICK UP
## ===============================
#func pick_up(carrier_node: Node2D):
	#being_carried = true
	#carrier = carrier_node
	#velocity = Vector2.ZERO
	#set_collision_layer_value(1, false)  # Disable world collision while floating
	#locked_to_timeline = false           # Unlock when manipulated
	#set_physics_process(true)            # Ensure physics runs
#
## ===============================
## ✋ DROP
## ===============================
#func drop():
	#being_carried = false
	#
#
	## Dropped by an ECHO → becomes new timeline truth
	#if carrier and carrier.is_in_group("echo"):
		#timeline_position = global_position
		#locked_to_timeline = false
#
		#var id = carrier.echo_id
		#if id not in influencing_echo_ids:
			#influencing_echo_ids.append(id)
#
	## Dropped by PLAYER outside recording → snap X, let gravity handle Y
	#elif carrier and carrier.is_in_group("player") and !Global.is_recording:
		#print("Hele b")
		#locked_to_timeline = true  # Lock horizontal only
		## Velocity.y remains unchanged so gravity applies
#
	## Dropped by PLAYER during recording → normal physics
	#elif carrier and carrier.is_in_group("player") and Global.is_recording:
		#print("11le b")
		#
		#locked_to_timeline = false
#
	#carrier = null
#
## ===============================
## ✨ FOLLOW WHILE CARRIED
## ===============================
#func follow_target(target_pos: Vector2):
	#if being_carried:
		#global_position = global_position.lerp(target_pos, 0.25)
#
## ===============================
## 🔄 WORLD RESET LOGIC
## ===============================
#func reset_if_needed(existing_echo_ids: Array):
	##print("Bitch leave me alonie")
	#if being_carried:
		#return
#
	#var still_valid := false
	#for id in influencing_echo_ids:
		#if id in existing_echo_ids:
			#still_valid = true
			#break
#
	#if still_valid:
		#global_position = timeline_position
	#else:
		#global_position = start_position
		#timeline_position = start_position
		#influencing_echo_ids.clear()
#
	#locked_to_timeline = false
	#set_physics_process(true)
	#velocity = Vector2.ZERO
#
#
#func _on_reset_timer_timeout() -> void:
	#print("restting")
	#global_position.x = timeline_position.x
	#global_position.y=timeline_position.y
	##pass # Replace with function body.

extends CharacterBody2D

# ===============================
# 🧠 TIME STATE MEMORY
# ===============================
var start_position: Vector2                 # Original spawn position
var timeline_position: Vector2              # Last valid drop position
var influencing_echo_ids: Array[int] = []   # Echoes that influenced this box

# When true, box is frozen horizontally at its timeline X
var locked_to_timeline := false

# ===============================
# 📦 CARRY SYSTEM
# ===============================
var being_carried := false
var carrier: Node2D = null

# ===============================
# 🌍 GRAVITY
# ===============================
const GRAVITY := 900.0

func _ready():
	start_position = global_position
	timeline_position = global_position
	add_to_group("carryable")
	add_to_group("resettable")

# ===============================
# 🔄 PHYSICS LOOP
# ===============================
var reset_timer_started := false

func _physics_process(delta):
	# Horizontal timeline lock when needed
	if locked_to_timeline and not being_carried:
		if not reset_timer_started:
			$ResetTimer.start()
			reset_timer_started = true
	else:
		reset_timer_started = false

	# Normal gravity when not carried
	if not being_carried:
		if not Global.is_recording:
			set_collision_layer_value(1, true)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		else:
			velocity.y = 0

	move_and_slide()

# ===============================
# ✋ PICK UP
# ===============================
func pick_up(carrier_node: Node2D):
	being_carried = true
	carrier = carrier_node
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)  # Disable world collision while floating
	locked_to_timeline = false           # Unlock when manipulated
	set_physics_process(true)            # Ensure physics runs

# ===============================
# ✋ DROP
# ===============================
func drop():
	being_carried = false
	
	if not carrier:
		return

	# Dropped by an ECHO → becomes new timeline truth
	if carrier.is_in_group("echo"):
		timeline_position = global_position
		var id = carrier.echo_id
		if id not in influencing_echo_ids:
			influencing_echo_ids.append(id)

	# Dropped by PLAYER outside recording → lock horizontal, keep vertical
	elif carrier.is_in_group("player") and not Global.is_recording:
		locked_to_timeline = true

	# Dropped by PLAYER during recording → normal physics
	elif carrier.is_in_group("player") and Global.is_recording:
		locked_to_timeline = false

	carrier = null

# ===============================
# ✨ FOLLOW WHILE CARRIED
# ===============================
func follow_target(target_pos: Vector2):
	if being_carried:
		global_position = global_position.lerp(target_pos, 0.25)

# ===============================
# 🔄 WORLD RESET LOGIC
# ===============================
func reset_if_needed(existing_echo_ids: Array):
	if being_carried:
		return

	# Remove any echo IDs that no longer exist
	#influencing_echo_ids = [id for id in influencing_echo_ids if id in existing_echo_ids]
	var new_ids: Array[int] = []
	for id in influencing_echo_ids:
		if id in existing_echo_ids:
			new_ids.append(id)
	influencing_echo_ids = new_ids
	if influencing_echo_ids.size() > 0:
		# Still has a valid influencing echo → stay at last drop
		global_position = timeline_position
	else:
		# No valid echoes → keep last drop instead of going back to spawn
		global_position = timeline_position
		influencing_echo_ids.clear()

	locked_to_timeline = false
	set_physics_process(true)
	velocity = Vector2.ZERO

# ===============================
# ⏲ RESET TIMER CALLBACK
# ===============================
func _on_reset_timer_timeout() -> void:
	print("resetting")
	# Snap back to timeline horizontal position
	global_position.x = timeline_position.x
	global_position.y=timeline_position.y
