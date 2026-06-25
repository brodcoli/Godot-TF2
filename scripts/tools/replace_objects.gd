extends Node
class_name ReplaceObjects

@export var map_node: Node3D
@export var string_in_obj_name: String = ""
@export var replace_with: PackedScene

func _ready() -> void:
	if map_node and replace_with and string_in_obj_name != "":
		_replace_recursive(map_node)

func _replace_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Node3D and string_in_obj_name in child.name:
			var new_node = replace_with.instantiate()
			node.add_child(new_node)
			if new_node is Node3D:
				new_node.global_transform = child.global_transform
			child.queue_free()
		else:
			_replace_recursive(child)
