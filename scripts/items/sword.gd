extends InventoryItem

@export var item_name := "Shovel"

func entered_inventory(actor: Actor) -> void:
	super.entered_inventory(actor)
	print("%s entered %s's inventory." % [item_name, actor.name])

func left_inventory(actor: Actor) -> void:
	super.left_inventory(actor)
	print("%s left %s's inventory." % [item_name, actor.name])

func held(actor: Actor) -> void:
	super.held(actor)
	print("%s is now held by %s." % [item_name, actor.name])

func no_longer_held(actor: Actor) -> void:
	super.no_longer_held(actor)
	print("%s is no longer held by %s." % [item_name, actor.name])

func used(actor: Actor) -> void:
	super.used(actor)
	print("%s used %s." % [actor.name, item_name])
