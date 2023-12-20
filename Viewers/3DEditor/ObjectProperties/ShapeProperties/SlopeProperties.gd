extends Control

const COLLISION_OVERLAY_MATERIAL = preload("res://Assets/Materials/CollisionOverlayDepth.material")
const SLOPE_COLLISION_SHAPE = preload("res://Viewers/3DEditor/Outlines/SlopeOutline.gd")

onready var _Extents := $VectorProperty

var _Node : Spatial = null
var _CollisionShape : MeshInstance = null
var _Origin : Vector3

func _exit_tree() -> void:
	if _CollisionShape:
		_CollisionShape.queue_free()

func set_enabled(enabled : bool) -> void:
	_Extents.enabled = enabled
	
	if enabled:
		create_shape()
	
	if _CollisionShape:
		_CollisionShape.visible = enabled

func create_shape() -> void:
	if !_CollisionShape && _Node:
		_CollisionShape = SLOPE_COLLISION_SHAPE.new()
		_CollisionShape.material_overlay = COLLISION_OVERLAY_MATERIAL
		var aabb := SpatialUtils.get_aabb(_Node)
		_CollisionShape.create_slope(aabb.size)
		_Origin = _Node.to_local(aabb.position) + aabb.size * 0.5
		_CollisionShape.translate(_Origin)
		_Node.add_child(_CollisionShape)
		_Extents.value = aabb.size * 0.5
		_Extents.default_value = _Extents.value

func set_transform(position : Vector3, rotation_degrees : Vector3) -> void:
	if _CollisionShape:
		_CollisionShape.transform.origin = _Origin + position
		_CollisionShape.rotation_degrees = rotation_degrees

func set_node(node : Spatial) -> void:
	_Node = node

func _on_VectorProperty_value_changed(value) -> void:
	_CollisionShape.create_slope(value * 2)
