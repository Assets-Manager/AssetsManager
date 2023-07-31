extends VBoxContainer

onready var _Translation := $Translation
onready var _RotationDegrees := $RotationDegrees
onready var _Scale := $Scale
onready var _Origin := $Origin
onready var _OriginView := $ViewportContainer

signal transform_changed(node)
signal origin_changed(node)

var _Node : Spatial = null

func set_node(node : Spatial) -> void:
	_Node = node
	
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
	_Node.transform.origin = value
	emit_signal("transform_changed", _Node)

func _on_RotationDegrees_value_changed(value : Vector3) -> void:
	_Node.rotation_degrees = value
	emit_signal("transform_changed", _Node)

func _on_Scale_value_changed(value : Vector3) -> void:
	_Node.scale = value
	emit_signal("transform_changed", _Node)

func _on_Origin_value_changed(value : Vector3) -> void:
	var aabb : AABB = SpatialUtils.get_aabb(_Node)
	aabb.position = _Node.to_local(aabb.position)
	_move_mesh(value - aabb.position)

func _on_OriginView_origin_point_pressed(point) -> void:
	var aabb : AABB = SpatialUtils.get_aabb(_Node)
	aabb.position = _Node.to_local(aabb.position)
	match point:
		OriginView.OriginPoint.TOP_LEFT_FRONT:
			_move_mesh(Vector3(-aabb.position.x, -aabb.position.y - aabb.size.y, -aabb.position.z - aabb.size.z))
			
		OriginView.OriginPoint.TOP_RIGHT_FRONT:
			_move_mesh(Vector3(-aabb.position.x - aabb.size.x, -aabb.position.y - aabb.size.y, -aabb.position.z - aabb.size.z))
			
		OriginView.OriginPoint.BOTTOM_LEFT_FRONT:
			_move_mesh(Vector3(-aabb.position.x, -aabb.position.y, -aabb.position.z - aabb.size.z))
			
		OriginView.OriginPoint.BOTTOM_RIGHT_FRONT:
			_move_mesh(Vector3(-aabb.position.x - aabb.size.x, -aabb.position.y, -aabb.position.z - aabb.size.z))
		
		OriginView.OriginPoint.TOP_LEFT_BACK:
			_move_mesh(Vector3(-aabb.position.x, -aabb.position.y - aabb.size.y, -aabb.position.z))
			
		OriginView.OriginPoint.TOP_RIGHT_BACK:
			_move_mesh(Vector3(-aabb.position.x - aabb.size.x, -aabb.position.y - aabb.size.y, -aabb.position.z))	
			
		OriginView.OriginPoint.BOTTOM_LEFT_BACK:
			_move_mesh(aabb.position * -1)
			
		OriginView.OriginPoint.BOTTOM_RIGHT_BACK:
			_move_mesh(Vector3(-aabb.position.x - aabb.size.x, -aabb.position.y, -aabb.position.z))
			
		OriginView.OriginPoint.CENTER:
			_move_mesh(aabb.position * -1 - aabb.size * 0.5)
			
		OriginView.OriginPoint.TOP_CENTER:
			var halfSize := aabb.size * 0.5
			_move_mesh(aabb.position * -1 - Vector3(halfSize.x, aabb.size.y, halfSize.z))
			
		OriginView.OriginPoint.BOTTOM_CENTER:
			var halfSize := aabb.size * 0.5
			_move_mesh(aabb.position * -1 - Vector3(halfSize.x, 0, halfSize.z))
			
		OriginView.OriginPoint.LEFT_CENTER:
			var halfSize := aabb.size * 0.5
			_move_mesh(aabb.position * -1 - Vector3(0, halfSize.y, halfSize.z))
			
		OriginView.OriginPoint.RIGHT_CENTER:
			var halfSize := aabb.size * 0.5
			_move_mesh(aabb.position * -1 - Vector3(aabb.size.x, halfSize.y, halfSize.z))
			
		OriginView.OriginPoint.BACK_CENTER:
			var halfSize := aabb.size * 0.5
			_move_mesh(aabb.position * -1 - Vector3(halfSize.x, halfSize.y, 0))
			
		OriginView.OriginPoint.FRONT_CENTER:
			var halfSize := aabb.size * 0.5
			_move_mesh(aabb.position * -1 - Vector3(halfSize.x, halfSize.y, aabb.size.z))

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

