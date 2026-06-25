class_name Interactable
extends Area3D

signal interacted(actor)

func interact(actor) -> void:
	interacted.emit(actor)
