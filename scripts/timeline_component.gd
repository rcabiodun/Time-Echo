extends Node

# ===============================
# 📡 SIGNALS
# ===============================
# on_reset  → fired when reset timer expires (object snaps back to timeline state)
# on_lock   → fired when player sets a lock outside recording
# on_echo_drop → fired when an echo finishes influencing this object
signal on_reset
signal on_lock
signal on_echo_drop

# ===============================
# 🧠 STATE
# ===============================
# locked_to_timeline → true when player manipulates outside recording,
# starts the reset timer and shows the player glitch shader
var locked_to_timeline := false

# being_interacted → true between begin_interaction and end_interaction calls
var being_interacted := false

# interactor → who is currently interacting (player or echo node)
var interactor: Node2D = null

# influencing_echo_ids → list of echo IDs that have manipulated this object.
# Used by reset_if_needed to decide whether to clear the lock.
var influencing_echo_ids: Array[int] = []

# reset_timer_started → prevents the timer from being restarted every frame
var reset_timer_started := false

# use_carry_shader_mode → when true, _handle_shaders() is skipped in _process.
# Objects like the box drive shaders manually via update_carry_state() instead.
# Objects like the platform use the default _handle_shaders() path.
var use_carry_shader_mode := false

var shader_strength := 1.0
# ===============================
# 🎨 SHADER MATERIALS
# ===============================
# Declared here, initialized once in _ready to avoid duplicate instances
var player_mat: ShaderMaterial
var echo_mat: ShaderMaterial

# visual → the sprite node to apply shaders to.
# Set externally by the parent via set_visual()
var visual: Node = null

# ===============================
# ⏲ TIMER
# ===============================
var reset_timer: Timer

# ===============================
# 🟢 READY
# ===============================
func _ready():
	# Create shader materials once — reusing the same instances is critical
	# so that visual.material == player_mat comparisons work correctly
	player_mat = ShaderMaterial.new()
	echo_mat   = ShaderMaterial.new()
	player_mat.shader = load("res://shaders/PlayerGlitchShader.gdshader")
	echo_mat.shader   = load("res://shaders/EchoTimelineShader.gdshader")

	# Create timer in code so no manual scene setup is needed
	reset_timer = Timer.new()
	reset_timer.one_shot = true
	reset_timer.wait_time = 0.5
	reset_timer.timeout.connect(_on_reset_timer_timeout)
	add_child(reset_timer)

# ===============================
# 🔄 PROCESS
# ===============================
func _process(_delta):
	_handle_timer()

	# Platform-style objects use this path — shaders driven by locked_to_timeline
	# Box-style objects skip this and call update_carry_state() manually instead
	if not use_carry_shader_mode:
		_handle_shaders()

# ===============================
# ⏲ TIMER LOGIC
# ===============================
func _handle_timer():
	if locked_to_timeline:
		if not reset_timer_started:
			reset_timer.start()
			reset_timer_started = true
	else:
		# Always clear this when not locked so the timer can retrigger
		# next time the object gets locked
		reset_timer_started = false

# ===============================
# 🎨 PLATFORM SHADER LOGIC
# Called every frame for platform-style objects (use_carry_shader_mode = false)
# ===============================
func _handle_shaders():
	if not visual:
		return

	var shader_applied := false

	# Recording always shows echo shader regardless of anything else
	if Global.is_recording:
		_apply_shader(echo_mat)
		shader_applied = true

	# Player locked this object outside recording → show player glitch shader
	elif locked_to_timeline:
		_apply_shader(player_mat)
		shader_applied = true

	# Echo is currently interacting → show echo shader
	elif being_interacted and interactor and interactor.is_in_group("echo"):
		_apply_shader(echo_mat)
		shader_applied = true

	if not shader_applied:
		_clear_shader()

# ===============================
# 🎨 CARRY SHADER LOGIC
# Called manually every physics frame by box-style objects.
# Completely separate from _handle_shaders so they never fight each other.
# ===============================
func update_carry_state(being_carried: bool, carrier: Node2D):
	if not visual:
		return

	var shader_applied := false

	# Recording always takes priority — echo shader
	if Global.is_recording:
		_apply_shader(echo_mat)
		shader_applied = true

	# Carried by player outside recording → player glitch shader
	elif being_carried and carrier and carrier.is_in_group("player") and not Global.is_recording:
		_apply_shader(player_mat)
		shader_applied = true

	# Carried by echo → echo shader
	elif being_carried and carrier and carrier.is_in_group("echo"):
		_apply_shader(echo_mat)
		shader_applied = true

	# locked after player dropped it → keep player shader visible until reset
	elif locked_to_timeline:
		_apply_shader(player_mat)
		shader_applied = true

	if not shader_applied:
		_clear_shader()

# ===============================
# 🖌 INTERNAL SHADER HELPERS
# ===============================
func _apply_shader(mat: ShaderMaterial):
	if not visual:
		return
	visual.material = mat
	mat.set_shader_parameter("flicker_amount", shader_strength)
	mat.set_shader_parameter("time_passed", Time.get_ticks_msec() / 1000.0)

func _clear_shader():
	if not visual:
		return
	if visual.material == player_mat:
		player_mat.set_shader_parameter("flicker_amount", 0.0)
	elif visual.material == echo_mat:
		echo_mat.set_shader_parameter("flicker_amount", 0.0)
	visual.material = null

# ===============================
# ✋ INTERACTION — called by parent around any manipulation
# ===============================
func begin_interaction(interactor_node: Node2D):
	# Store who is interacting and clear any existing lock
	being_interacted = true
	interactor = interactor_node
	locked_to_timeline = false

func end_interaction():
	being_interacted = false

	if not interactor:
		return

	# Echo finished → record its ID as an influencer
	if interactor.is_in_group("echo"):
		var id = interactor.echo_id
		if id not in influencing_echo_ids:
			influencing_echo_ids.append(id)
		emit_signal("on_echo_drop")

	# Player finished outside recording → lock and start the reset countdown
	elif interactor.is_in_group("player") and not Global.is_recording:
		locked_to_timeline = true
		emit_signal("on_lock")

	# Player finished during recording → stay free, no lock
	elif interactor.is_in_group("player") and Global.is_recording:
		locked_to_timeline = false

	interactor = null

# ===============================
# 🔄 WORLD RESET — called by the reset manager
# ===============================
func reset_if_needed(existing_echo_ids: Array):
	# Remove echo IDs that no longer exist in the world
	var new_ids: Array[int] = []
	for id in influencing_echo_ids:
		if id in existing_echo_ids:
			new_ids.append(id)
	influencing_echo_ids = new_ids

	# Clear lock regardless — parent handles snapping position/rotation
	locked_to_timeline = false
	reset_timer_started = false
	reset_timer.stop()

# ===============================
# ⏲ TIMER CALLBACK
# ===============================
func _on_reset_timer_timeout():
	locked_to_timeline = false
	reset_timer_started = false
	_clear_shader()
	emit_signal("on_reset")

# ===============================
# 🔧 SET VISUAL — called by parent in _ready
# ===============================
func set_visual(node: Node):
	visual = node
