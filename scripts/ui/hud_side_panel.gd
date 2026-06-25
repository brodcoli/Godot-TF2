extends Control

@export var clip: int = 0:
	set(value):
		clip = value
		%ClipLabel.text = str(clip)

@export var amount: int = 0:
	get:
		return amount
	set(value):
		amount = value
		%AmmoLabel.text = str(amount)
