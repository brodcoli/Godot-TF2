extends Node3D
class_name ResupplyPack

@onready var _area = $Area3D

func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is Actor:
		body.refill_inventory_items()

		for i in 5:
			body.health += body.max_health / 5
			await get_tree().create_timer(0.02).timeout
