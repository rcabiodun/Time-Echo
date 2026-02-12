extends Node

# List of rune IDs this object requires
@export var required_runes: Array[String] = []

func are_required_runes_active() -> bool:
	print("These are the required rune IDs: " + ", ".join(required_runes))

	if required_runes.is_empty():
		return true  # No rune requirement

	var active_echo_ids: Array[int] = []
	for echo in get_tree().get_nodes_in_group("echo"):
		active_echo_ids.append(echo.echo_id)

	for rune in get_tree().get_nodes_in_group("runes"):
		if rune.rune_id in required_runes:
			var valid := false
			for id in rune.activated_by_echo_ids:
				if id in active_echo_ids:
					valid = true
					break
			if not valid:
				return false

	return true
