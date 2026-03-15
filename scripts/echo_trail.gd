extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func setup(animation_name: String, frame: int, position: Vector2, flip_h: bool, tint: Color = Color(0.5,0.7,1,0.5)):
	global_position = position
	sprite.animation = animation_name
	sprite.frame = frame
	sprite.flip_h = flip_h
	sprite.modulate = tint

	# Fade out alpha over time and free
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(Callable(self, "queue_free"))
