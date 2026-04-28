# LevelCompleteScreen.gd
extends CanvasLayer

signal retry_pressed
signal next_pressed
signal menu_pressed
# Called when the screen is instantiated – hide initially
func _ready() -> void:
	visible = true
	Global._play_ui_sfx(Global.UISound.MENU_OPEN)

# Call this to display results (called from LevelManager)
func show_results(shards: int, total: int, level_num: int) -> void:
	#Global._showing_menu=true
	Global._play_ui_sfx(Global.UISound.MENU_OPEN)
	$"Panel/VBoxContainer/CompletionLabel".text = "Level " + str(level_num) + " Complete!"
	$"Panel/VBoxContainer/ShardsLabel".text = "Time Shards: " + str(shards) + " / " + str(total)
	visible = true

func _on_retry_button_pressed() -> void:
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	
	visible = false
	#Global._showing_menu=false
	print("retry button ppressed")
	emit_signal("retry_pressed")
func _on_next_button_pressed() -> void:
	#Global._showing_menu=false
	Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	
	visible = false
	print("next button ppressed")
	#Global._play_ui_sfx(Global.UISound.BUTTON_SELECT)
	
	emit_signal("next_pressed")
	#emit_signal("menu_pressed")



# Existing show_results function stays the same

func show_results_for_replay(shards: int, total: int, level_num: int) -> void:
	$Panel/VBoxContainer/CompletionLabel.text = "Level " + str(level_num) + " Complete!"
	$Panel/VBoxContainer/ShardsLabel.text = "Time Shards: " + str(shards) + " / " + str(total)
	# Replace the "Next" button with "Menu"
	var next_button = $Panel/VBoxContainer/HBoxContainer/NextButton
	next_button.text = "Menuuu"
	# Disconnect any previous connections, then connect to menu
	if next_button.is_connected("pressed", _on_next_button_pressed):
		next_button.disconnect("pressed", _on_next_button_pressed)
	next_button.pressed.connect(_on_menu_button_pressed)
	visible = true

func _on_menu_button_pressed() -> void:
	visible = false
	emit_signal("next_pressed")
	
	emit_signal("menu_pressed")
	
