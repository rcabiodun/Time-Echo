extends Area2D

# Unique ID for this rune in the level
@export var rune_id: String = "R1"

# Which echoes have activated this rune
var activated_by_echo_ids: Array[int] = []

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("echo"):
		var id = body.echo_id
		if id not in activated_by_echo_ids:
			activated_by_echo_ids.append(id)
			print("Rune ", rune_id, " activated by echo ", id)
			# Notify doors to re-check rune status
			for door in get_tree().get_nodes_in_group("doors"):
				door._check_runes_now()


# Called by level reset system
func reset_rune_if_needed(existing_echo_ids: Array[int]):
	# Remove activations from echoes that no longer exist
	activated_by_echo_ids = activated_by_echo_ids.filter(
		func(id): return id in existing_echo_ids
	)
