extends Node









const DEFAULT_MATERIAL = "ROCK"

func do_raycast(position: Vector3, direction: Vector3, max_distance: float = 1000.0) -> String:
	var space_state = get_viewport().find_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(position, position + direction.normalized() * max_distance)
	var result = space_state.intersect_ray(query)

	if result.is_empty():
		return DEFAULT_MATERIAL

	var collider = result.collider
	if not collider:
		return DEFAULT_MATERIAL

	var parent = collider.get_parent()
	if not parent:
		return DEFAULT_MATERIAL

	var parent_name: String = parent.name
	var mat_start = parent_name.find("(MAT=")
	if mat_start != -1:
		mat_start += 5
		var mat_end = parent_name.find(")", mat_start)
		if mat_end != -1:
			return parent_name.substr(mat_start, mat_end - mat_start)

	return DEFAULT_MATERIAL
