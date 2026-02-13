extends CharacterBody2D

# ===============================
# 🎮 MOVEMENT CONSTANTS
# ===============================
const SPEED := 300.0
const JUMP_VELOCITY := -400.0

# ===============================
# ⏺ RECORDING SETTINGS
# ===============================
const MAX_RECORD_TIME := 15.0

# ===============================
# ✨ JUMP FEEL SETTINGS
# ===============================
@export var COYOTE_TIME := 0.12
@export var JUMP_BUFFER_TIME := 1

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

# ===============================
# 📦 TELEKINESIS CARRY SYSTEM
# ===============================
var carried_box: Node2D = null
@export var carry_distance := 52.0
@onready var pickup_area = $PickupArea #character is facing the right by default
var interacted_this_frame := false
var facing_direction: float = 1.0 

# ===============================
# ⏺ RECORDING STATE
# ===============================
#var Global.is_recording: bool = false
var record_timer: float = 0.0
var recorded_frames: Array = []

signal create_echo(frames)

# ===============================
# 🔄 MAIN PHYSICS LOOP
# ===============================
func _physics_process(delta: float) -> void:
	update_recording_label() 
	apply_gravity(delta)
	update_timers(delta)
	handle_jump()
	handle_movement(delta)
	handle_interact()
	handle_recording(delta)

	move_and_slide()

	update_carried_box_position()


func update_recording_label():
	#func _process(delta):
	var new_text = "Recording!" if Global.is_recording else ""
	if $CanvasLayer/Label.text != new_text:
		$CanvasLayer/Label.text = new_text



# ===============================
# 🌍 GRAVITY
# ===============================
func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

# ===============================
# ⏱ COYOTE + BUFFER TIMERS
# ===============================
func update_timers(delta):
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

# ===============================
# 🦘 JUMP
# ===============================
func handle_jump():
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

# ===============================
# 🏃 MOVEMENT
# ===============================
func handle_movement(delta):
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		facing_direction = direction  # Remember last move direction
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 4 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 6 * delta)
		
# ===============================
# ✋ INTERACT (PICK UP / DROP BOX)
# ===============================
func handle_interact():
	interacted_this_frame = false  # Reset each frame
	if Input.is_action_just_pressed("interact"):
		interacted_this_frame = true

		print("Pressing interact button")
		# Drop if already carrying
		if carried_box:
			carried_box.drop()
			carried_box = null
			return

		# Try picking up nearby carryable object
		for body in pickup_area.get_overlapping_bodies():
			var box = body# StaticBody → Box root
			
			if box and box.is_in_group("carryable"):
				carried_box = box
				box.pick_up(self)
				break


# Move the carried box every frame
func update_carried_box_position():
	if carried_box:
		#var dir:float = sign(velocity.x)
		var dir: float = facing_direction

		if dir == 0:
			dir = 1  # Default to right if standing still

		var target_pos:Vector2 = global_position + Vector2(dir * carry_distance, -12)
		carried_box.follow_target(target_pos)

# ===============================
# ⏺ RECORDING SYSTEM
# ===============================
func handle_recording(delta):
	if Input.is_action_just_pressed("start_recording") and not Global.is_recording:
		start_recording()

	if Input.is_action_just_pressed("stop_recording") and Global.is_recording:
		stop_recording()

	if Global.is_recording:
		record_timer += delta

		recorded_frames.append({
			"position": global_position,
			"velocity": velocity,
			"interact": interacted_this_frame,
			"carrying": carried_box != null
			})

		if record_timer >= MAX_RECORD_TIME:
			stop_recording()

func start_recording():
	recorded_frames.clear()
	record_timer = 0
	Global.is_recording = true
	print("Recording started")

func stop_recording():
	if not Global.is_recording:
		return

	Global.is_recording = false
	record_timer = 0
	print("Recording stopped")
	create_echo.emit(recorded_frames.duplicate(true))
