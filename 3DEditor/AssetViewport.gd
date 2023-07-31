extends Spatial

const GdAssimpLoader = preload("res://Native/GDAssimpLoader.gdns")

onready var _Assets := $Asset
onready var _Pivot := $Pivot
onready var _Outline := $Outline

signal asset_loaded(asset_scene)

func load_asset(path : String) -> void:
	for c in _Assets.get_children():
		c.queue_free()
		
	var loader = GdAssimpLoader.new()
	var loaded = loader.load(path)
	var tmp = loaded.instance()
	_Assets.add_child(tmp)
	
	emit_signal("asset_loaded", tmp)
	
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
