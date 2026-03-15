extends CharacterBody2D

# ===============================
# 🧠 TIME STATE MEMORY
# ===============================
# timeline_position = the last confirmed valid position set by an echo or player.
# When the reset timer fires we snap back here.
var timeline_position: Vector2

# pre_recording_position = snapshot taken the moment recording starts.
# When recording stops we revert here so the echo replays from the correct state.
var pre_recording_position: Vector2

# ===============================
# 📦 CARRY SYSTEM
# ===============================
var being_carried := false
var carrier: Node2D = null

# ===============================
# 🌍 GRAVITY
# ===============================
const GRAVITY := 900.0

# ===============================
# 📦 NODE REFERENCES
# ===============================
@onready var visual: Sprite2D = $Visual
@onready var timeline: Node = $TimelineComponent

# ===============================
# 🟢 READY
# ===============================
func _ready():
	timeline_position = global_position
	pre_recording_position = global_position

	timeline.set_visual($Visual)
	timeline.use_carry_shader_mode = true  # ← this is missing!
	timeline.shader_strength=1
	timeline.on_reset.connect(_on_timeline_reset)
	Global.recording_started.connect(_on_recording_started)
	Global.recording_stopped.connect(_on_recording_stopped)
	add_to_group("carryable")
	add_to_group("resettable")

# ===============================
# 🎙 RECORDING CALLBACKS
# ===============================
func _on_recording_started():
	# Snapshot the position the moment recording begins so we know
	# what state to revert to when recording ends
	pre_recording_position = global_position

func _on_recording_stopped():
	# Revert to pre-recording position so the echo replays
	# from the correct state rather than wherever the player
	# left the box during recording
	global_position = pre_recording_position

# ===============================
# 🔄 PHYSICS LOOP
# ===============================
func _physics_process(delta):
	# Hand off shader updates to the timeline component every frame.
	# We pass being_carried and carrier so it can decide which shader
	# to apply (player glitch, echo shimmer, or none)
	timeline.update_carry_state(being_carried, carrier)

	# Normal gravity when not carried
	if not being_carried:
		if not Global.is_recording:
			#print("here")
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
	print("picked box")
	
	being_carried = true
	carrier = carrier_node
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)  # Disable world collision while floating

	# Tell timeline component who picked it up — clears lock state internally
	timeline.begin_interaction(carrier_node)

# ===============================
# ✋ DROP
# ===============================
func drop():
	print("Dropped box")
	being_carried = false

	if not carrier:
		return

	# Dropped by ECHO → this position is now confirmed timeline truth
	if carrier.is_in_group("echo"):
		timeline_position = global_position
	#else:
		
	# Tell the timeline component the interaction ended.
	# Internally it decides whether to lock (player outside recording),
	# stay free (player during recording), or confirm echo influence.
	timeline.end_interaction()

	carrier = null

# ===============================
# ✨ FOLLOW WHILE CARRIED
# ===============================
func follow_target(target_pos: Vector2):
	if being_carried:
		global_position = global_position.lerp(target_pos, 0.25)

# ===============================
# ⏲ TIMELINE RESET CALLBACK
# ===============================
func _on_timeline_reset():
	# Fired by TimelineComponent when the reset timer expires
	# after a player lock — snap back to last valid timeline position
	global_position = timeline_position

# ===============================
# 🔄 WORLD RESET — CALLED BY RESET MANAGER
# ===============================
func reset_if_needed(existing_echo_ids: Array):
	if being_carried:
		return

	# Delegate echo ID cleanup and lock clearing to the timeline component
	timeline.reset_if_needed(existing_echo_ids)

	# Always snap to last known valid position
	global_position = timeline_position
	velocity = Vector2.ZERO
	set_physics_process(true)
