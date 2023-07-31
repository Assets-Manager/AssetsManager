extends VBoxContainer

const CUBE_PROPERTIES = preload("res://3DEditor/ObjectProperties/ShapeProperties/CubeProperties.tscn")
const SPHERE_PROPERTIES = preload("res://3DEditor/ObjectProperties/ShapeProperties/SphereProperties.tscn")
const CYLINDER_PROPERTIES = preload("res://3DEditor/ObjectProperties/ShapeProperties/CylinderProperties.tscn")
const SLOPE_PROPERTIES = preload("res://3DEditor/ObjectProperties/ShapeProperties/SlopeProperties.tscn")

var _Node : Spatial = null
var _ShapeProperties : Control = null

onready var _Translation := $Translation
onready var _Rotation := $Rotation

func _ready() -> void:
	_on_OptionButton_item_selected(0)

func set_node(node : Spatial) -> void:
	_Node = node
	if _ShapeProperties:
		_ShapeProperties.set_node(_Node)

func _on_OptionButton_item_selected(index: int) -> void:
	if _ShapeProperties:
		_ShapeProperties.queue_free()
		_ShapeProperties = null
	
	match index:
		0:	# Cube
			_ShapeProperties = CUBE_PROPERTIES.instance()
		1: # Sphere
			_ShapeProperties = SPHERE_PROPERTIES.instance()
		2:	# Cylinder
			_ShapeProperties = CYLINDER_PROPERTIES.instance()
		3:	# Slope
			_ShapeProperties = SLOPE_PROPERTIES.instance()
	
	if _ShapeProperties:
		_ShapeProperties.set_node(_Node)
		add_child(_ShapeProperties)
		move_child(_ShapeProperties, get_child_count() - 3)
		_ShapeProperties.create_shape()

func _on_EnableCollision_toggled(button_pressed: bool) -> void:
	for i in range(1, get_child_count()):
		if get_child(i).has_method("set_enabled"):
			get_child(i).set_enabled(button_pressed)
		elif get_child(i).has_method("set_disabled"):
			get_child(i).set_disabled(!button_pressed)

func _on_Translation_value_changed(value : Vector3) -> void:
	if _ShapeProperties:
		_ShapeProperties.set_transform(_Translation.value, _Rotation.value)

func _on_Rotation_value_changed(value : Vector3) -> void:
	if _ShapeProperties:
		_ShapeProperties.set_transform(_Translation.value, _Rotation.value)
