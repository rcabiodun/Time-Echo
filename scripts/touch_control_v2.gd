extends HBoxContainer

#@onready var left: TouchScreenButton = $left
#@onready var right: TouchScreenButton = $right
#@onready var jump: TouchScreenButton = $jump
#@onready var record: TouchScreenButton = $record
#@onready var interact: TouchScreenButton = $interact
#@onready var stop: TouchScreenButton = $stop
@onready var left: TouchScreenButton = $Control/HBoxContainer/Control2/left
@onready var right: TouchScreenButton = $Control/HBoxContainer/Control/right
@onready var jump: TouchScreenButton = $Control2/HBoxContainer/Control2/jump
@onready var record: TouchScreenButton = $Control2/HBoxContainer/Control/record
@onready var stop: TouchScreenButton = $Control2/HBoxContainer/Control/stop
@onready var interact: TouchScreenButton = $Control2/HBoxContainer/Control/interact

func _ready() -> void:
	update_interact_button()
	update_record_buttons()

func _process(_delta: float) -> void:
	update_record_buttons()
	update_interact_button()

# =============================
# RECORD BUTTON VISIBILITY LOGIC
# =============================
func update_record_buttons() -> void:
	record.visible = !Global.is_recording
	stop.visible = Global.is_recording

# =============================
# INTERACT BUTTON OPACITY LOGIC
# =============================
func update_interact_button() -> void:
	if Global.player_around_interactable:
		interact.modulate.a = 1.0
	else:
		interact.modulate.a = 0.5

# =============================
# LEFT
# =============================
func _on_left_pressed() -> void:
	left.modulate.a = 0.5

func _on_left_released() -> void:
	left.modulate.a = 1.0

# =============================
# RIGHT
# =============================
func _on_right_pressed() -> void:
	right.modulate.a = 0.5

func _on_right_released() -> void:
	right.modulate.a = 1.0

# =============================
# JUMP
# =============================
func _on_jump_pressed() -> void:
	jump.modulate.a = 0.5

func _on_jump_released() -> void:
	jump.modulate.a = 1.0

# =============================
# RECORD
# =============================
func _on_record_pressed() -> void:
	record.modulate.a = 0.5

func _on_record_released() -> void:
	record.modulate.a = 1.0

# =============================
# STOP
# =============================
func _on_stop_pressed() -> void:
	pass

func _on_stop_released() -> void:
	pass

# =============================
# INTERACT
# =============================
func _on_interact_pressed() -> void:
	if Global.player_around_interactable:
		interact.modulate.a = 0.5

func _on_interact_released() -> void:
	update_interact_button()


func _on_touch_screen_button_pressed() -> void:
	#pass # Replace with function body.
	if Global.is_recording:
		Input.action_press("stop_recording") 
	DeathManager.trigger_death_freeze_and_fade()
