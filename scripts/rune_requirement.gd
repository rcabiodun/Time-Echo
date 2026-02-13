extends Node

# List of rune IDs this object requires
@export var required_runes: Array[String] = []


func are_required_runes_active_for_echo(echo_id: int) -> bool:
	if required_runes.is_empty():
		return true

	for rune_id in required_runes:
		var rune_node = null
		for rune in get_tree().get_nodes_in_group("runes"):
			if rune.rune_id.strip_edges() == rune_id.strip_edges():
				rune_node = rune
				break

		if rune_node == null:
			return false

		if echo_id not in rune_node.activated_by_echo_ids:
			return false

	return true

func are_required_runes_active() -> bool:
	if required_runes.is_empty():
		return true  # no runes → door can open

	# Get all current echoes
	var echoes = get_tree().get_nodes_in_group("echo")
	for echo in echoes:
		var echo_id = echo.echo_id
		var all_runes_hit = true

		for rune_id in required_runes:
			# Find the rune node
			var rune_node = null
			for rune in get_tree().get_nodes_in_group("runes"):
				if rune.rune_id.strip_edges() == rune_id.strip_edges():  # remove whitespace
					rune_node = rune
					break

			if rune_node == null:
				all_runes_hit = false
				break

			if echo_id not in rune_node.activated_by_echo_ids:
				all_runes_hit = false
				break

		if all_runes_hit:
			return true  # found a single echo that activated all required runes

	return false  # no echo hit all runes
