extends VBoxContainer

onready var _Translation := $Translation
onready var _RotationDegrees := $RotationDegrees
onready var _Scale := $Scale
onready var _Origin := $Origin
onready var _OriginView := $ViewportContainer

signal transform_changed(node)
signal origin_changed(node)
signal add_history(history_object)

var _Node : Spatial = null
var _History : History = null

func set_node_and_history(node : Spatial, history : History) -> void:
	_Node = node
	_History = history
	
	_fill_input_fields()

func _fill_input_fields() -> void:
	_Translation.value = _Node.transform.origin	
	_RotationDegrees.value = _Node.rotation_degrees	
	_Scale.value = _Node.scale
	_Scale.default_value = Vector3.ONE
	
	_Origin.visible = _Node is MeshInstance
	_OriginView.visible = _Origin.visible
	
	if _Origin.visible:
		var aabb : AABB = SpatialUtils.get_aabb(_Node)
		aabb.position = _Node.to_local(aabb.position)
		_Origin.value = aabb.position
		_Origin.default_value = _Origin.value

func _on_Translation_value_changed(value : Vector3) -> void:
	var old = _Node.transform
	_Node.transform.origin = value
	_add_tranforms_history(old, _Node.transform)
	emit_signal("transform_changed", _Node)

func _on_RotationDegrees_value_changed(value : Vector3) -> void:
	var old = _Node.transform
	_Node.rotation_degrees = value
	_add_tranforms_history(old, _Node.transform)
	emit_signal("transform_changed", _Node)

func _on_Scale_value_changed(value : Vector3) -> void:
	var old = _Node.transform
	_Node.scale = value
	_add_tranforms_history(old, _Node.transform)
	emit_signal("transform_changed", _Node)

func _add_tranforms_history(old : Transform, new : Transform) -> void:
	_History.create_undo_action("Transform changed")
	_History.add_undo_property(_Node, "transform", old)
	_History.add_do_property(_Node, "transform", new)
	_History.add_do_method(self, "_on_undo_redo_history", null)
	_History.add_undo_method(self, "_on_undo_redo_history", null)
	_History.commit_undo_action()

func _on_undo_redo_history(_val) -> void:
	_fill_input_fields()
	emit_signal("transform_changed", _Node)

func _on_Origin_value_changed(value : Vector3) -> void:
	var aabb : AABB = SpatialUtils.get_aabb(_Node)
	aabb.position = _Node.to_local(aabb.position)
	
	var distance := value - aabb.position
	_add_origin_history(distance)
	_move_mesh(distance)

func _on_OriginView_origin_point_pressed(point) -> void:
	var aabb : AABB = SpatialUtils.get_aabb(_Node)
	aabb.position = _Node.to_local(aabb.position)
	var distance : Vector3
	
	match point:
		OriginView.OriginPoint.TOP_LEFT_FRONT:
			distance = (Vector3(-aabb.position.x, -aabb.position.y - aabb.size.y, -aabb.position.z - aabb.size.z))
			
		OriginView.OriginPoint.TOP_RIGHT_FRONT:
			distance = (Vector3(-aabb.position.x - aabb.size.x, -aabb.position.y - aabb.size.y, -aabb.position.z - aabb.size.z))
			
		OriginView.OriginPoint.BOTTOM_LEFT_FRONT:
			distance = (Vector3(-aabb.position.x, -aabb.position.y, -aabb.position.z - aabb.size.z))
			
		OriginView.OriginPoint.BOTTOM_RIGHT_FRONT:
			distance = (Vector3(-aabb.position.x - aabb.size.x, -aabb.position.y, -aabb.position.z - aabb.size.z))
		
		OriginView.OriginPoint.TOP_LEFT_BACK:
			distance = (Vector3(-aabb.position.x, -aabb.position.y - aabb.size.y, -aabb.position.z))
			
		OriginView.OriginPoint.TOP_RIGHT_BACK:
			distance = (Vector3(-aabb.position.x - aabb.size.x, -aabb.position.y - aabb.size.y, -aabb.position.z))	
			
		OriginView.OriginPoint.BOTTOM_LEFT_BACK:
			distance = (aabb.position * -1)
			
		OriginView.OriginPoint.BOTTOM_RIGHT_BACK:
			distance = (Vector3(-aabb.position.x - aabb.size.x, -aabb.position.y, -aabb.position.z))
			
		OriginView.OriginPoint.CENTER:
			distance = (aabb.position * -1 - aabb.size * 0.5)
			
		OriginView.OriginPoint.TOP_CENTER:
			var halfSize := aabb.size * 0.5
			distance = (aabb.position * -1 - Vector3(halfSize.x, aabb.size.y, halfSize.z))
			
		OriginView.OriginPoint.BOTTOM_CENTER:
			var halfSize := aabb.size * 0.5
			distance = (aabb.position * -1 - Vector3(halfSize.x, 0, halfSize.z))
			
		OriginView.OriginPoint.LEFT_CENTER:
			var halfSize := aabb.size * 0.5
			distance = (aabb.position * -1 - Vector3(0, halfSize.y, halfSize.z))
			
		OriginView.OriginPoint.RIGHT_CENTER:
			var halfSize := aabb.size * 0.5
			distance = (aabb.position * -1 - Vector3(aabb.size.x, halfSize.y, halfSize.z))
			
		OriginView.OriginPoint.BACK_CENTER:
			var halfSize := aabb.size * 0.5
			distance = (aabb.position * -1 - Vector3(halfSize.x, halfSize.y, 0))
			
		OriginView.OriginPoint.FRONT_CENTER:
			var halfSize := aabb.size * 0.5
			distance = (aabb.position * -1 - Vector3(halfSize.x, halfSize.y, aabb.size.z))
			
	_add_origin_history(distance)
	_move_mesh(distance)

func _add_origin_history(distance : Vector3) -> void:
	_History.create_undo_action("Origin changed")
	_History.add_do_method(self, "_move_mesh", distance)
	_History.add_undo_method(self, "_move_mesh", -distance)
	_History.commit_undo_action()

func _move_mesh(distance : Vector3) -> void:
	var mdt := MeshDataTool.new()
	var mesh : ArrayMesh = _Node.mesh
	
	for i in mesh.get_surface_count():
		mdt.create_from_surface(_Node.mesh, 0)
		for vi in range(mdt.get_vertex_count()):
			var vertex = mdt.get_vertex(vi)
			vertex += distance
			mdt.set_vertex(vi, vertex)
		mesh.surface_remove(0)
		mdt.commit_to_surface(mesh)
		
	var aabb : AABB = SpatialUtils.get_aabb(_Node)
	aabb.position = _Node.to_local(aabb.position)
	_Origin.value = aabb.position
		
	emit_signal("origin_changed", _Node)

