extends IViewer

const NODE_PROPERTIES = preload("res://Viewers/3DEditor/ObjectProperties/ObjectProperties.tscn")

onready var _SceneTree : Tree = $Split/Panel/Properties/SceneTree
onready var _AssetViewport := $Split/ViewportContainer/Viewport/AssetViewport
onready var _Properties := $Split/Panel/Properties
onready var _Viewport := $Split/ViewportContainer/Viewport
onready var _History : History = History.new()

var _PropertyEditors : Dictionary = {}
var _CurrentPropertyEditor : Control = null
var _TabIndex : int = 0

var _GoBackShortcut : InputEventKey
var _GoForwardShortcut : InputEventKey

func _ready():
	_GoBackShortcut = InputEventKey.new()
	_GoBackShortcut.scancode = KEY_Z
	_GoBackShortcut.pressed = true
	_GoBackShortcut.control = true
	
	_GoForwardShortcut = InputEventKey.new()
	_GoForwardShortcut.scancode = KEY_Z
	_GoForwardShortcut.pressed = true
	_GoForwardShortcut.control = true
	_GoForwardShortcut.shift = true

func _input(event):
	if event.shortcut_match(_GoBackShortcut):
		_History.go_back()
	elif event.shortcut_match(_GoForwardShortcut):
		_History.go_forward()

func load_asset(asset_id : int) -> int:
	var path = AssetsLibrary.get_asset_path(asset_id)
	if path.empty():
		return FAILED
	
	var loader : IFormatImporter = AssetsLibrary.find_importer(path.get_extension())
	if loader:
		var data = loader.load_format(path)
		if data is PackedScene:
			data = data.instance()
		elif !(data is Spatial):	# Only 3D nodes are supported
			return FAILED
		
		_AssetViewport.load_asset(data)
		_build_tree(null, data)
	
	return OK

func cleanup() -> void:
	for k in _PropertyEditors:
		_PropertyEditors[k].queue_free()
	_PropertyEditors.clear()
	
	_SceneTree.clear()
	_AssetViewport.cleanup()
	_History.clear()

func _build_tree(parent : TreeItem, node : Spatial) -> void:
	var treeItem : TreeItem = _SceneTree.create_item(parent)
	treeItem.set_text(0, node.name)
	treeItem.set_metadata(0, node)
	
	for c in node.get_children():
		_build_tree(treeItem, c)

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
		_CurrentPropertyEditor.set_node_and_history(node, _History)
		_CurrentPropertyEditor.current_tab = _TabIndex
		_CurrentPropertyEditor.connect("tab_changed", self, "_tab_changed")

func _transform_changed(node : Spatial) -> void:
	_AssetViewport.show_pivot(node.global_transform.origin)
	_show_outline(node)
	
func _origin_changed(node : Spatial) -> void:
	_show_outline(node)

func _tab_changed(idx: int) -> void:
	_TabIndex = idx
