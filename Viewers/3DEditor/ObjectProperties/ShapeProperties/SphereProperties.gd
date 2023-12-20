extends VBoxContainer

const COLLISION_OVERLAY_MATERIAL = preload("res://Assets/Materials/CollisionOverlayDepth.material")
const SPHERE_COLLISION_SHAPE = preload("res://Viewers/3DEditor/Outlines/SphereOutline.gd")

var _Node : Spatial = null
var _CollisionShape : MeshInstance = null

onready var _NumericEdit := $NumericEdit
onready var _Slider := $HSlider

var _LockShapeCreation := false
var _Origin : Vector3

func _exit_tree() -> void:
	if _CollisionShape:
		_CollisionShape.queue_free()

func set_enabled(enabled : bool) -> void:
	_NumericEdit.editable = enabled
	
	if enabled:
		create_shape()
			
	if _CollisionShape:
		_CollisionShape.visible = enabled

func _on_HSlider_value_changed(value: float) -> void:
	_NumericEdit.value = value
	create_shape()

func _on_NumericEdit_value_changed(value) -> void:
	_Slider.value = value
	create_shape()

func create_shape() -> void:
	if _LockShapeCreation:
		return
		
	_LockShapeCreation = true
	
	if !_CollisionShape && _Node:
		_CollisionShape = SPHERE_COLLISION_SHAPE.new()
		_CollisionShape.material_overlay = COLLISION_OVERLAY_MATERIAL
		var aabb := SpatialUtils.get_aabb(_Node)
		var radius : float = max(aabb.size.x, max(aabb.size.y, aabb.size.z)) * 0.5
		_CollisionShape.create_sphere(radius)
		_Origin = _Node.to_local(aabb.position) + Vector3(radius, radius, radius)
		_CollisionShape.translate(_Origin)
		_Node.add_child(_CollisionShape)
		_Slider.value = radius
		_NumericEdit.value = radius
	elif _CollisionShape:
		_CollisionShape.create_sphere(_NumericEdit.value)
	
	_LockShapeCreation = false

func set_transform(position : Vector3, rotation_degrees : Vector3) -> void:
	if _CollisionShape:
		_CollisionShape.transform.origin = _Origin + position
		_CollisionShape.rotation_degrees = rotation_degrees

func set_node(node : Spatial) -> void:
	_Node = node
