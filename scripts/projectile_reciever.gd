extends StaticBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var elevator_id: String = "elevator:A"

signal projectile_receiver_activated(elevator_id: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite_2d.play("off")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("projectile"):
		print("Emiiting activation signal")
		projectile_receiver_activated.emit(elevator_id)
		animated_sprite_2d.play("on")


func _on_reset_timer_timeout() -> void:
	pass # Replace with function body.
