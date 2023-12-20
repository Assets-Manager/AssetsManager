class_name SpatialUtils
extends Object

static func _vec_min(a : Vector3, b : Vector3) -> Vector3:
	return Vector3(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z))
	
static func _vec_max(a : Vector3, b : Vector3) -> Vector3:
	return Vector3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z))

# Gets or calculated the total boundingbox of the node.
static func get_aabb(node : Spatial, include_children : bool = false) -> AABB:
	var pos : Vector3 = Vector3(INF, INF, INF)
	var end : Vector3 = Vector3.ZERO
	
	if node.has_method("get_aabb"):
		var aabb : AABB = node.get_aabb()
		var global : Transform = Transform()
		global = global.translated(node.global_transform.origin)
		global.basis = global.basis.scaled(node.global_transform.basis.get_scale())

		pos = global.xform(aabb.position)
		end = global.xform(aabb.end)
	
	if !node.has_method("get_aabb") || include_children:
		for c in node.get_children():
			var aabb := get_aabb(c, true)
			pos = _vec_min(pos, aabb.position)
			end = _vec_max(end, aabb.end)
	
	return AABB(pos, end - pos)
