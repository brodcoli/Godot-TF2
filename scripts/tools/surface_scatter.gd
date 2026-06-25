@tool
extends Node3D
class_name SurfaceScatter

@export_category("Actions")
@export_tool_button("Perform Scatter", "Callable") var _generate_scatter_action = _generate_scatter

@export_category("References")
@export var target_terrain: Node3D
@export var mesh_to_scatter: PackedScene
@export var multimesh_data_path := "res://multimesh_data"

@export_category("Settings")
@export var target_color: Color = Color.GREEN
@export var color_tolerance: float = 0.05
@export var grass_density: float = 1.0
@export var scale_variation: Vector2 = Vector2(0.8, 1.2)

@export_category("Chunking")
@export var chunk_size: Vector3 = Vector3(200, 400, 200)
@export var visibility_range: float = 200.0


@onready var _init_visibility = visible

func _generate_scatter() -> void:

	if not Engine.is_editor_hint():
		return

	if not target_terrain or not mesh_to_scatter:
		printerr("Grass Scatter: Missing terrain or grass mesh references.")
		return

	var instanced_grass := mesh_to_scatter.instantiate()
	var actual_mesh: Mesh = null

	if instanced_grass is MeshInstance3D and instanced_grass.mesh:
		actual_mesh = instanced_grass.mesh
	else:
		var found_meshes: Array[MeshInstance3D] = []
		_find_mesh_instances(instanced_grass, found_meshes)
		for mi in found_meshes:
			if mi.mesh:
				actual_mesh = mi.mesh
				break

	instanced_grass.queue_free()

	if not actual_mesh:
		printerr("Grass Scatter: Could not find a valid Mesh inside mesh_to_scatter PackedScene.")
		return

	var meshes: Array[MeshInstance3D] = []
	_find_mesh_instances(target_terrain, meshes)

	if meshes.is_empty():
		printerr("Grass Scatter: No MeshInstance3D found in target_terrain.")
		return

	var valid_triangles := []
	var total_grass_count := 0


	for mi in meshes:
		if not mi.mesh:
			continue

		var array_mesh := mi.mesh as ArrayMesh
		if not array_mesh:
			continue

		var mdt := MeshDataTool.new()
		var error := mdt.create_from_surface(array_mesh, 0)
		if error != OK:
			continue

		var relative_transform: Transform3D = target_terrain.global_transform.affine_inverse() * mi.global_transform

		for i in range(mdt.get_face_count()):
			var v1_idx := mdt.get_face_vertex(i, 0)
			var v2_idx := mdt.get_face_vertex(i, 1)
			var v3_idx := mdt.get_face_vertex(i, 2)

			var c1 := mdt.get_vertex_color(v1_idx).linear_to_srgb()
			var c2 := mdt.get_vertex_color(v2_idx).linear_to_srgb()
			var c3 := mdt.get_vertex_color(v3_idx).linear_to_srgb()

			var v_target := Vector3(target_color.r, target_color.g, target_color.b)
			var match_1 = Vector3(c1.r, c1.g, c1.b).distance_to(v_target) <= color_tolerance
			var match_2 = Vector3(c2.r, c2.g, c2.b).distance_to(v_target) <= color_tolerance
			var match_3 = Vector3(c3.r, c3.g, c3.b).distance_to(v_target) <= color_tolerance


			if match_1 and match_2 and match_3:
				var v1 := relative_transform * mdt.get_vertex(v1_idx)
				var v2 := relative_transform * mdt.get_vertex(v2_idx)
				var v3 := relative_transform * mdt.get_vertex(v3_idx)
				var face_normal := (relative_transform.basis * mdt.get_face_normal(i)).normalized()


				var edge1 := v2 - v1
				var edge2 := v3 - v1
				var area := (edge1.cross(edge2)).length() * 0.5
				var count := int(area * grass_density)

				if count > 0:
					valid_triangles.append({
						"v1": v1, "v2": v2, "v3": v3,
						"normal": face_normal,
						"count": count
					})
					total_grass_count += count

	if total_grass_count == 0:
		print("Grass Scatter: No matching triangles found or area too small.")
		return


	var chunks := {}

	for tri in valid_triangles:
		var v1: Vector3 = tri.v1
		var v2: Vector3 = tri.v2
		var v3: Vector3 = tri.v3
		var normal: Vector3 = tri.normal

		for j in range(tri.count):

			var u := randf()
			var v := randf()
			var sqrt_u := sqrt(u)

			var point := (1.0 - sqrt_u) * v1 + (sqrt_u * (1.0 - v)) * v2 + (sqrt_u * v) * v3


			var up := normal
			var random_dir := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()


			if random_dir.length_squared() < 0.001 or abs(random_dir.dot(up)) > 0.99:
				random_dir = Vector3(1, 0, 0)

			var right := random_dir.cross(up).normalized()
			var fwd := up.cross(right).normalized()

			var basis := Basis(right, up, fwd)


			var s := randf_range(scale_variation.x, scale_variation.y)
			basis = basis.scaled(Vector3(s, s, s))

			var chunk_coord := Vector3(
				floor(point.x / chunk_size.x),
				floor(point.y / chunk_size.y),
				floor(point.z / chunk_size.z)
			)

			if not chunks.has(chunk_coord):
				chunks[chunk_coord] = []
			chunks[chunk_coord].append(Transform3D(basis, point))


	var container = get_node_or_null("ScatterContainer")
	if container:
		container.free()


	var old_mmi = get_node_or_null("ScatterMultiMesh")
	if old_mmi:
		old_mmi.free()

	container = Node3D.new()
	container.name = "ScatterContainer"
	add_child(container)
	container.owner = get_tree().edited_scene_root

	if not DirAccess.dir_exists_absolute(multimesh_data_path):
		DirAccess.make_dir_absolute(multimesh_data_path)

	var parent_name = get_parent().name if get_parent() else "root"
	var specific_data_path = multimesh_data_path + "/" + parent_name + "_" + name

	if DirAccess.dir_exists_absolute(specific_data_path):
		var dir := DirAccess.open(specific_data_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".res"):
					dir.remove(file_name)
				file_name = dir.get_next()
	else:
		DirAccess.make_dir_absolute(specific_data_path)


	for chunk_coord in chunks.keys():
		var transforms: Array = chunks[chunk_coord]
		var chunk_center = chunk_coord * chunk_size + chunk_size * 0.5

		var multi_mesh := MultiMesh.new()
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.instance_count = transforms.size()
		multi_mesh.mesh = actual_mesh

		for i in range(transforms.size()):
			var t: Transform3D = transforms[i]

			t.origin -= chunk_center
			multi_mesh.set_instance_transform(i, t)

		var mmi := MultiMeshInstance3D.new()
		var cx := int(chunk_coord.x)
		var cy := int(chunk_coord.y)
		var cz := int(chunk_coord.z)

		mmi.name = "Chunk_" + str(cx) + "_" + str(cy) + "_" + str(cz)
		if visibility_range > 0.0:
			mmi.visibility_range_end = visibility_range

		container.add_child(mmi)
		mmi.owner = get_tree().edited_scene_root

		var save_path = specific_data_path + "/data_" + str(cx) + "_" + str(cy) + "_" + str(cz) + ".res"

		multi_mesh.take_over_path(save_path)

		var err := ResourceSaver.save(multi_mesh, save_path, ResourceSaver.FLAG_COMPRESS)
		mmi.multimesh = multi_mesh
		if err != OK:
			printerr("Surface Scatter: Failed to save multimesh resource to ", save_path)


		var chunk_transform := Transform3D(Basis(), chunk_center)
		mmi.global_transform = target_terrain.global_transform * chunk_transform

	print("Surface Scatter: Successfully spawned ", total_grass_count, " grass blades across ", chunks.size(), " chunks.")

func _find_mesh_instances(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_find_mesh_instances(child, result)


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		if Settings.disable_surface_scatters:
			visible = false
		else:
			visible = _init_visibility
