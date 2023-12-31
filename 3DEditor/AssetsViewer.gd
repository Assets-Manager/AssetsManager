extends HSplitContainer

const NODE_PROPERTIES = preload("res://3DEditor/ObjectProperties/ObjectProperties.tscn")

onready var _SceneTree : Tree = $Panel/Properties/SceneTree
onready var _AssetViewport := $ViewportContainer/Viewport/AssetViewport
onready var _Properties := $Panel/Properties

var _PropertyEditors : Dictionary = {}
var _CurrentPropertyEditor : Control = null
var _TabIndex : int = 0

func _build_tree(parent : TreeItem, node : Spatial) -> void:
	var treeItem : TreeItem = _SceneTree.create_item(parent)
	treeItem.set_text(0, node.name)
	treeItem.set_metadata(0, node)
	
	for c in node.get_children():
		_build_tree(treeItem, c)

func _on_AssetViewport_asset_loaded(asset_scene : Spatial) -> void:
	_build_tree(null, asset_scene)

func _show_outline(node : Spatial) -> void:
	var aabb = SpatialUtils.get_aabb(node)
	_AssetViewport.show_outline(node.global_transform.basis.get_euler(), AABB(aabb.position + aabb.size * 0.5, aabb.size))

func _on_SceneTree_item_selected() -> void:
	var item : TreeItem =  _SceneTree.get_selected()
	var node : Spatial = item.get_metadata(0)
	
	if node is MeshInstance:
		_AssetViewport.show_pivot(node.global_transform.origin)
	else:
		_AssetViewport.hide_pivot()
	
	_show_outline(node)
	
	if _CurrentPropertyEditor:
		_CurrentPropertyEditor.visible = false
	
	if _PropertyEditors.has(node.get_path()):
		_CurrentPropertyEditor = _PropertyEditors[node.get_path()]
		_CurrentPropertyEditor.visible = true
		_CurrentPropertyEditor.current_tab = _TabIndex
	else:
		_CurrentPropertyEditor = NODE_PROPERTIES.instance()
		_CurrentPropertyEditor.connect("transform_changed", self, "_transform_changed")
		_CurrentPropertyEditor.connect("origin_changed", self, "_origin_changed")
		_CurrentPropertyEditor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_CurrentPropertyEditor.visible = true
		_Properties.add_child(_CurrentPropertyEditor)
		_PropertyEditors[node.get_path()] = _CurrentPropertyEditor
		_CurrentPropertyEditor.set_node(node)
		_CurrentPropertyEditor.current_tab = _TabIndex
		_CurrentPropertyEditor.connect("tab_changed", self, "_tab_changed")

func _transform_changed(node : Spatial) -> void:
	_AssetViewport.show_pivot(node.global_transform.origin)
	_show_outline(node)
	
func _origin_changed(node : Spatial) -> void:
	_show_outline(node)

func _tab_changed(idx: int) -> void:
	_TabIndex = idx
