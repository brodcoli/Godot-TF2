extends Node


signal all_systems_ready

var _pending_tasks: Dictionary = {}
var _is_fully_loaded: bool = false


func register_task(task_name: String) -> void:
	if _is_fully_loaded:
		push_warning("Tried to register task '%s' but loading is already finished!" % task_name)
		return

	_pending_tasks[task_name] = false
	print("Registered task: ", task_name)
	_update_progress()


func complete_task(task_name: String) -> void:
	if _pending_tasks.has(task_name) and not _pending_tasks[task_name]:
		_pending_tasks[task_name] = true
		print("Completed task: ", task_name)
		_update_progress()
		_check_completion()
	else:
		push_warning("Tried to complete unknown or already finished task: ", task_name)

func _check_completion() -> void:

	for task_name in _pending_tasks:
		if _pending_tasks[task_name] == false:
			return


	_finish_loading()

func _update_progress() -> void:
	if OS.has_feature("web"):
		var total: int = _pending_tasks.size()
		if total == 0:
			return

		var completed: int = 0
		for task_status in _pending_tasks.values():
			if task_status:
				completed += 1

		var percent: float = float(completed) / float(total)
		JavaScriptBridge.eval("if (typeof window.updateGodotLoadingProgress === 'function') window.updateGodotLoadingProgress(%f);" % percent)

func _finish_loading() -> void:
	_is_fully_loaded = true
	print("All loading tasks completed. Hiding web overlay.")
	all_systems_ready.emit()

	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.hideGodotLoadingScreen();")
