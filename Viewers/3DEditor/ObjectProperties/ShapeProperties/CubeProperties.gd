extends Control

const COLLISION_OVERLAY_MATERIAL = preload("res://Assets/Materials/CollisionOverlayDepth.material")
const CUBE_COLLISION_SHAPE = preload("res://Viewers/3DEditor/Outlines/CubeOutline.gd")

onready var _Extends := $VectorProperty

var _Node : Spatial = null
var _CollisionShape : MeshInstance = null
var _Origin : Vector3

func _exit_tree() -> void:
	if _CollisionShape:
		_CollisionShape.queue_free()

func set_enabled(enabled : bool) -> void:
	_Extends.enabled = enabled
	
	if enabled:
		create_shape()
			
	if _CollisionShape:
		_CollisionShape.visible = enabled

func create_shape() -> void:
	if !_CollisionShape && _Node:
		_CollisionShape = CUBE_COLLISION_SHAPE.new()
		_CollisionShape.material_overlay = COLLISION_OVERLAY_MATERIAL
		var aabb := SpatialUtils.get_aabb(_Node)
		_CollisionShape.create_cube(aabb.size)
		_Origin = _Node.to_local(aabb.position) + aabb.size * 0.5
		_CollisionShape.translate(_Origin)
		_Node.add_child(_CollisionShape)
		_Extends.value = aabb.size * 0.5
		_Extends.default_value = _Extends.value

func set_transform(position : Vector3, rotation_degrees : Vector3) -> void:
	if _CollisionShape:
		_CollisionShape.transform.origin = _Origin + position
		_CollisionShape.rotation_degrees = rotation_degrees

func set_node(node : Spatial) -> void:
	_Node = node

func _on_VectorProperty_value_changed(value) -> void:
	_CollisionShape.create_cube(value * 2)
