extends StaticBody2D

# ===============================
# 🧭 DIRECTION SYSTEM
# ===============================
# All 8 possible directions the platform can face.
# direction_index points to which one is currently active.
var DIRECTIONS = [
	Vector2.RIGHT,                # 0 - Right
	Vector2(1, -1).normalized(),  # 1 - Top-Right
	Vector2.UP,                   # 2 - Up
	Vector2(-1, -1).normalized(), # 3 - Top-Left
	Vector2.LEFT,                 # 4 - Left
	Vector2(-1, 1).normalized(),  # 5 - Bottom-Left
	Vector2.DOWN,                 # 6 - Down
	Vector2(1, 1).normalized()    # 7 - Bottom-Right
]
const DIRECTION_NAMES = [
	"Right", "Top-Right", "Up", "Top-Left",
	"Left", "Bottom-Left", "Down", "Bottom-Right"
]

# The current facing direction index (can be set in inspector per platform)
@export var direction_index: int = 0

# ===============================
# 🧠 TIME STATE MEMORY
# ===============================
# timeline_direction_index = the last "confirmed" direction that should
# be treated as real/valid in the timeline. When the reset timer fires,
# we snap back to this.
var timeline_direction_index: int = 0

# pre_recording_direction_index = snapshot of direction taken the moment
# recording starts. When recording stops, we revert to this so the echo
# replays from the correct state rather than from wherever the player
# left it mid-recording.
var pre_recording_direction_index: int = 0

# ===============================
# 📦 NODE REFERENCES
# ===============================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

# TimelineComponent handles all the shader logic, lock state,
# reset timer, and echo tracking — we just talk to it via signals.
@onready var timeline: Node = $TimelineComponent
#timeline
# ===============================
# 🟢 READY
# ===============================
func _ready():
	# Save the starting direction as the initial timeline truth
	timeline_direction_index = direction_index
	pre_recording_direction_index = direction_index

	# Hand the sprite to the timeline component so it knows what to shade
	#timeline.player_shader_strength=0.5
	timeline.shader_strength=1
	timeline.set_visual($AnimatedSprite2D)

	# Listen for when the timeline component fires its reset signal
	# (this happens when the reset timer runs out after a player lock)
	timeline.on_reset.connect(_on_timeline_reset)

	# Listen for recording state changes from Global so we can
	# snapshot and restore direction around recording sessions
	Global.recording_started.connect(_on_recording_started)
	Global.recording_stopped.connect(_on_recording_stopped)

	sprite.play("default")
	update_visual_rotation()
	print_current_direction()

# ===============================
# 🎙 RECORDING CALLBACKS
# ===============================
func _on_recording_started():
	# Snapshot the current direction the moment recording begins.
	# This is the state the world was in BEFORE the player started
	# recording, so it's what we revert to when recording ends.
	pre_recording_direction_index = direction_index

func _on_recording_stopped():
	# When recording stops, revert to the pre-recording direction.
	# This ensures the echo starts replaying from the correct state
	# rather than from wherever the player rotated it during recording.
	direction_index = pre_recording_direction_index
	update_visual_rotation()

# ===============================
# ✋ INTERACT — CALLED BY PLAYER OR ECHO
# ===============================
func interact(interactor: Node2D):
	# Tell the timeline component who is interacting.
	# Internally it sets being_interacted = true and stores the interactor.
	timeline.begin_interaction(interactor)

	# Do the actual rotation
	rotate_platform()

	# If an echo is the one rotating, this is now the confirmed
	# timeline truth — save it so resets snap back here.
	if interactor.is_in_group("echo"):
		timeline_direction_index = direction_index

	# Tell the timeline component the interaction is done.
	# Internally it decides whether to lock (player outside recording),
	# ignore (player during recording), or confirm echo influence.
	timeline.end_interaction()

# ===============================
# 🔄 ROTATION
# ===============================
func rotate_platform():
	# Step one index counter-clockwise (wraps around with modulo)
	print("rotating platform")
	direction_index = (direction_index - 1 + 8) % 8
	update_visual_rotation()
	print_current_direction()

func update_visual_rotation():
	# Convert the current direction vector to an angle and apply it
	# to the whole platform node so the sprite and collider rotate together
	rotation = DIRECTIONS[direction_index].angle()

# ===============================
# ⏲ TIMELINE RESET CALLBACK
# ===============================
func _on_timeline_reset():
	# Fired by TimelineComponent when the reset timer expires after
	# a player lock. Snap back to the last valid timeline direction.
	direction_index = timeline_direction_index
	update_visual_rotation()

# ===============================
# 🔄 WORLD RESET — CALLED BY RESET MANAGER
# ===============================
func reset_if_needed(existing_echo_ids: Array):
	# Delegate to the timeline component which checks if any of the
	# echoes that influenced this platform still exist. If not, it
	# clears the lock and lets the object settle naturally.
	timeline.reset_if_needed(existing_echo_ids)

# ===============================
# 📦 PROJECTILE REDIRECTION
# ===============================
func get_redirect_direction() -> Vector2:
	# Returns the current facing direction as a Vector2 so projectiles
	# can query this and bounce/redirect accordingly
	return DIRECTIONS[direction_index]

# ===============================
# 📢 DEBUG
# ===============================
func print_current_direction():
	print("--- Platform Direction ---")
	print("Index:     ", direction_index)
	print("Facing:    ", DIRECTION_NAMES[direction_index])
	print("Vector:    ", DIRECTIONS[direction_index].round())
	print("Rotation:  ", rad_to_deg(rotation), "°")
	print("---------------------------")
