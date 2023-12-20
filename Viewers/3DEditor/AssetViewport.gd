extends Spatial

const GdAssimpLoader = preload("res://Native/GDAssimpLoader.gdns")

onready var _Assets := $Asset
onready var _Pivot := $Pivot
onready var _Outline := $Outline

func load_asset(node : Spatial) -> void:
	_Assets.add_child(node)
	
func cleanup() -> void:
	for c in _Assets.get_children():
		c.queue_free()
		
	hide_pivot()
	hide_outline()
	
func show_pivot(pos : Vector3) -> void:
	_Pivot.global_transform.origin = pos
	_Pivot.visible = true
	
func hide_pivot() -> void:
	_Pivot.visible = false
	
func show_outline(euler_rotation : Vector3, aabb : AABB) -> void:
	_Outline.global_transform.origin = aabb.position
	_Outline.create_cube(aabb.size)
	_Outline.rotation = euler_rotation
	
	_Outline.visible = true
	
func hide_outline() -> void:
	_Outline.visible = false
