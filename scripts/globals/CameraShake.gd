# CameraShake.gd (autoload singleton)
extends Node

var camera: Camera2D = null
var trauma: float = 0.0           # current shake strength (0–1)
var decay: float = 0.8            # how fast trauma fades [0.6–0.95 typical]
var max_offset: Vector2 = Vector2(80, 60)   # max pixels to shake (tweak per game scale)
var max_roll: float = 0.07        # max rotation in radians (small value!)

var noise: FastNoiseLite = FastNoiseLite.new()
var time: float = 0.0

func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 3.0          # lower = smoother, higher = more frantic
	noise.seed = randi()           # random each run, or fixed for consistency

func _process(delta: float) -> void:
	if trauma <= 0:
		if camera:
			camera.offset = Vector2.ZERO
			camera.rotation = 0.0
		return
	
	# Decay trauma over time
	trauma = max(trauma - decay * delta, 0.0)
	
	time += delta
	
	if camera:
		var shake_amount = pow(trauma, 2)   # square it → feels more natural (or use pow(trauma, 3))
		
		# Offset
		var x = noise.get_noise_2d(time * 100, 0) * max_offset.x * shake_amount
		var y = noise.get_noise_2d(0, time * 100) * max_offset.y * shake_amount
		camera.offset = Vector2(x, y)
		
		# Optional rotation (adds impact, but don't overdo)
		var r = noise.get_noise_2d(time * 150, 200) * max_roll * shake_amount
		camera.rotation = r

# Public method — call this from anywhere!
func shake(amount: float = 0.5, decay_override: float = -1, custom_max_offset: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0: return
	
	trauma = clamp(trauma + amount, 0.0, 1.0)
	
	if decay_override > 0:
		decay = decay_override  # temporary override possible
	
	if custom_max_offset != Vector2.ZERO:
		max_offset = custom_max_offset  # one-shot override
	
	# Auto-find camera if we lost it (e.g. scene change)
	if not camera or not is_instance_valid(camera):
		camera = _find_active_camera()

func _find_active_camera() -> Camera2D:
	var root = get_tree().root
	var cam_group = get_tree().get_nodes_in_group("camera")  # optional: add your camera to group "camera"
	
	if not cam_group.is_empty():
		return cam_group[0] as Camera2D
	
	# Fallback: search current scene for first Camera2D
	var scene = get_tree().current_scene
	if scene:
		var cam = scene.get_viewport().get_camera_2d()
		if cam:
			return cam
	return null
