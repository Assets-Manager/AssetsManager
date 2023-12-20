extends VBoxContainer

const COLLISION_OVERLAY_MATERIAL = preload("res://Assets/Materials/CollisionOverlayDepth.material")
const CYLINDER_COLLISION_SHAPE = preload("res://Viewers/3DEditor/Outlines/CylinderOutline.gd")

var _Node : Spatial = null
var _CollisionShape : MeshInstance = null
var _Origin : Vector3

onready var _Radius := $NumericEdit
onready var _SliderRadius := $HSlider
onready var _Height := $NumericEdit2

var _LockShapeCreation := false

func _exit_tree() -> void:
	if _CollisionShape:
		_CollisionShape.queue_free()

func set_enabled(enabled : bool) -> void:
	_Radius.editable = enabled
	_Height.editable = enabled
	
	if enabled:
		create_shape()
			
	if _CollisionShape:
		_CollisionShape.visible = enabled

func _on_HSlider_value_changed(value: float) -> void:
	_Radius.value = value
	create_shape()

func create_shape() -> void:
	if _LockShapeCreation:
		return
		
	_LockShapeCreation = true
	
	if !_CollisionShape && _Node:
		_CollisionShape = CYLINDER_COLLISION_SHAPE.new()
		_CollisionShape.material_overlay = COLLISION_OVERLAY_MATERIAL
		var aabb := SpatialUtils.get_aabb(_Node)
		var radius : float = max(aabb.size.x, aabb.size.z) * 0.5
		print(aabb.size.y)
		_CollisionShape.create_cylinder(radius, aabb.size.y)
		_Origin = _Node.to_local(aabb.position) + Vector3(radius, aabb.size.y * 0.5, radius)
		_CollisionShape.translate(_Origin)
		_Node.add_child(_CollisionShape)
		_SliderRadius.value = radius
		_Radius.value = radius
		_Height.value = aabb.size.y
	elif _CollisionShape:
		_CollisionShape.create_cylinder(_Radius.value, _Height.value)
		
	_LockShapeCreation = false

func set_transform(position : Vector3, rotation_degrees : Vector3) -> void:
	if _CollisionShape:
		_CollisionShape.transform.origin = _Origin + position
		_CollisionShape.rotation_degrees = rotation_degrees

func set_node(node : Spatial) -> void:
	_Node = node

func _on_NumericEdit2_value_changed(value) -> void:
	create_shape()

func _on_NumericEdit_value_changed(value) -> void:
	_SliderRadius.value = value
	create_shape()
