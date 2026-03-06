extends Node2D

@onready var light: PointLight2D = $PointLight2D


# ===============================
# 🎨 EDITABLE FROM INSPECTOR
# ===============================
@export var glow_color: Color = Color.CYAN
@export var max_energy: float = 2.0
@export var grow_speed: float = 3.0
@export var shrink_speed: float = 4.0


func _ready():
	light.color = glow_color
	light.energy = 0.0


func _physics_process(delta):

	if Global.is_recording:
		light.energy = min(
			light.energy + grow_speed * delta,
			max_energy
		)
	else:
		light.energy = max(
			light.energy - shrink_speed * delta,
			0.0
		)
