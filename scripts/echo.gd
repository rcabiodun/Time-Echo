extends CharacterBody2D

# ===============================
# 🎞 PLAYBACK DATA
# ===============================

# All recorded frames from the player
var playback_frames: Array = []

# Which frame we are currently replaying
var playback_index: int = 0


# ===============================
# 📦 CARRY SYSTEM (same as player)
# ===============================

var carried_box: Node2D = null
@export var carry_distance := 52.0

# Used to keep box on correct side when not moving
var facing_direction: float = 1.0

# Detection area (Echo scene must have an Area2D named PickupArea)
@onready var pickup_area: Area2D = $PickupArea


# ===============================
# 🚀 CALLED BY LEVEL TO START PLAYBACK
# ===============================
func start_playback(frames: Array):

	# If no data, remove echo
	if frames.is_empty():
		queue_free()
		return

	playback_frames = frames.duplicate(true)
	playback_index = 0

	# Start at first recorded position
	global_position = playback_frames[0]["position"]
	velocity = playback_frames[0]["velocity"]


# ===============================
# 🔄 MAIN PLAYBACK LOOP
# ===============================
func _physics_process(delta):

	# Stop when timeline ends
	if playback_index >= playback_frames.size():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var frame = playback_frames[playback_index]

	# Apply recorded movement exactly
	global_position = frame["position"]
	velocity = frame["velocity"]

	# Remember last movement direction for carrying boxes
	if velocity.x != 0:
		facing_direction = sign(velocity.x)

	# Replay interaction if player pressed interact this frame
	if frame.has("interact") and frame["interact"]:
		handle_interaction()

	move_and_slide()

	update_carried_box_position()

	playback_index += 1


# ===============================
# ✋ INTERACTION REPLAY
# ===============================
func handle_interaction():

	# If already holding a box → drop it
	if carried_box:
		carried_box.drop()
		carried_box = null
		return

	# Otherwise try to pick up a nearby carryable box
	for body in pickup_area.get_overlapping_bodies():
		if body.is_in_group("carryable"):
			carried_box = body
			body.pick_up(self)
			break


# ===============================
# 📦 BOX FOLLOW WHILE CARRIED
# ===============================
func update_carried_box_position():
	if carried_box:
		var target_pos: Vector2 = global_position + Vector2(facing_direction * carry_distance, -12)
		carried_box.follow_target(target_pos)
