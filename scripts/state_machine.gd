extends Node
class_name StateMachine

@export var initial_state: State

signal done_with_physics

var current_state: State
var prev_state: State
var states: Dictionary = {}

func _ready():
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(_on_child_transition)

	if initial_state:
		initial_state.state_enter()
		current_state = initial_state

func _process(delta: float):
	if current_state:
		current_state.state_process(delta)

func _physics_process(delta: float):
	if current_state:
		current_state.state_physics_process(delta)
		done_with_physics.emit()

func _input(event: InputEvent):
	if current_state:
		current_state.state_input(event)

func _on_child_transition(state: State, new_state_name: String):
	if state != current_state:
		return
	change_state(new_state_name)

func current_state_name():
	return current_state.name.to_lower()

func get_prev_state_name():
	return prev_state.name.to_lower()

func change_state(new_state_name: String):
	var new_state = states.get(new_state_name.to_lower())
	if not new_state:
		return

	if current_state:
		await done_with_physics
		current_state.state_exit()
	new_state.state_enter()

	prev_state = current_state
	current_state = new_state
