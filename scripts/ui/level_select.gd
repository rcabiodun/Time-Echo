extends CanvasLayer

const MAX_LEVELS := 20   # adjust to total rooms
const LEVEL_BUTTON_THEME = preload("uid://digybdtiyu5wj")

@onready var scroll_container: ScrollContainer = $Panel/VBoxContainer/ScrollContainer
@onready var level_grid: GridContainer = $Panel/VBoxContainer/ScrollContainer/LevelGrid
@onready var total_shards_label: Label = $Panel/VBoxContainer/TotalShardsLabel
@onready var back_button: Button = $Panel/VBoxContainer/BackButton


func _ready():
	Global._play_ui_sfx(Global.UISound.MENU_OPEN)
	back_button.pressed.connect(_on_back_pressed)
	generate_level_buttons()
	update_total_shards()
	call_deferred("scroll_to_current_level")   # scroll after layout


func generate_level_buttons():
	for child in level_grid.get_children():
		child.queue_free()

	for lvl in range(1, MAX_LEVELS + 1):
		var button := Button.new()
		button.theme = LEVEL_BUTTON_THEME
		button.text = "Level " + str(lvl)
		button.custom_minimum_size = Vector2(120, 80)

		if lvl < GameProgression.current_level:
			var data = GameProgression.level_data.get(lvl, {})
			var c = data.get("shards_collected", 0)
			var t = data.get("shards_total", 0)
			button.text += "\n★ " + str(c) + "/" + str(t)
			button.disabled = false
		elif lvl == GameProgression.current_level:
			button.text += "\n▶ Play"
			button.disabled = false
		else:
			button.text += "\n🔒"
			button.disabled = true

		button.pressed.connect(_on_level_button_pressed.bind(lvl))
		level_grid.add_child(button)


func update_total_shards():
	total_shards_label.text = "Total Shards: " + str(GameProgression.total_shards)


func _on_level_button_pressed(level: int):
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	if level < GameProgression.current_level:
		Global.selected_level = level
		Global.replay_mode = true
	elif level == GameProgression.current_level:
		Global.selected_level = level
		Global.replay_mode = false
	get_tree().change_scene_to_file("res://scenes/levels/level_proc.tscn")


func _on_back_pressed():
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func scroll_to_current_level() -> void:
	var target_lvl = GameProgression.current_level
	if target_lvl < 1 or target_lvl > MAX_LEVELS:
		return

	# The button for level X is at index X-1 in the grid children
	var idx = target_lvl - 1
	if idx >= level_grid.get_child_count():
		return

	var target_button = level_grid.get_child(idx)
	if not target_button:
		return

	# Wait for the grid to finish layout
	await get_tree().process_frame

	var btn_top = target_button.position.y
	var margin = 20   # small space so the button isn't glued to the top edge
	scroll_container.scroll_vertical = max(0, btn_top - margin)
