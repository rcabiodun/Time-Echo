extends CanvasLayer

@onready var stats_label = $Panel/VBoxContainer/Label2
@onready var rooms_label = $Panel/VBoxContainer/Label3
@onready var log_label = $Panel/VBoxContainer/Label4

var log_lines: Array[String] = []

func _input(event):
	if event.is_action_pressed("debug_toggle"):
		visible = !visible

func update_stats(difficulty, echoes, runes):
	print("Updating stats")
	stats_label.text = "Difficulty: %d\nEcho Capacity: %d\nRunes: %d" % [
		difficulty, echoes, runes
	]

func update_rooms(room_list):
	print("Updating rooms")
	
	var text = "Rooms:\n"
	for i in range(room_list.size()):
		text += "%d: %s\n" % [i, room_list[i]]
	rooms_label.text = text

func add_log(message: String):
	print("Adding log")
	log_lines.append(message)

	# Keep only last 10 logs
	if log_lines.size() > 10:
		log_lines.pop_front()

	log_label.text = "Log:\n" + "\n".join(log_lines)
