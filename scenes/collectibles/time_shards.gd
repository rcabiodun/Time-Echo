extends StaticBody2D

@onready var shard_pickup: AudioStreamPlayer2D = $ShardPickup
@onready var collection_area: Area2D = $CollectionArea
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var float_speed := 2.0
var float_height := 6.0
var base_y := 0.0
var time := 0.0

signal time_shard_collected

func _ready() -> void:
	#animated_sprite_2d.play("shimmer")
	base_y = position.y


func _process(delta: float) -> void:
	time += delta * float_speed
	position.y = base_y + sin(time) * float_height


func _on_collection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collection_area.set_deferred("monitoring", false) # disable further triggers
		visible = false # hide shard
		
		shard_pickup.play()
		await shard_pickup.finished
		emit_signal("time_shard_collected")
		queue_free()
