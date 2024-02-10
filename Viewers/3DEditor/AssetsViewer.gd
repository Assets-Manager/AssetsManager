extends IViewer

const NODE_PROPERTIES = preload("res://Viewers/3DEditor/ObjectProperties/ObjectProperties.tscn")

onready var _SceneTree : Tree = $VBoxContainer/Split/Panel/Properties/SceneTree
onready var _AssetViewport := $VBoxContainer/Split/ViewportContainer/Viewport/AssetViewport
onready var _Properties := $VBoxContainer/Split/Panel/Properties
onready var _Viewport := $VBoxContainer/Split/ViewportContainer/Viewport
onready var _History : History = History.new()
onready var _Save := $VBoxContainer/MarginContainer/HBoxContainer/Save
onready var _Close := $VBoxContainer/MarginContainer/HBoxContainer/Close
onready var _UnsavedChangesDialog := $CanvasLayer/UnsavedChangesDialog

var _PropertyEditors : Dictionary = {}
var _CurrentPropertyEditor : Control = null
var _TabIndex : int = 0

var _HasChanges : bool = true

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
	
	_UnsavedChangesDialog.get_ok().text = tr("Save")
	var button = _UnsavedChangesDialog.add_button(tr("No"), true, "no")
	
	# Move the new button to the middle.
	button.get_parent().move_child(button, 3)
	button.get_parent().move_child(button.get_parent().get_children()[button.get_parent().get_child_count() - 1], 4)

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
	_CurrentPropertyEditor = null
	
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

func _update_has_changes(changes : bool) -> void:
	_HasChanges = changes
	_Save.disabled = !_HasChanges

func _transform_changed(node : Spatial) -> void:
	_AssetViewport.show_pivot(node.global_transform.origin)
	_show_outline(node)
	_update_has_changes(true)
	
func _origin_changed(node : Spatial) -> void:
	_show_outline(node)
	_update_has_changes(true)

func _tab_changed(idx: int) -> void:
	_TabIndex = idx

func _on_Close_pressed():
	if _HasChanges:
		_UnsavedChangesDialog.popup_centered()
		return
	
	WindowManager.show_main_window()

func _on_Save_pressed():
	_update_has_changes(false)

func _on_UnsavedChangesDialog_confirmed():
	_on_Save_pressed()
	WindowManager.show_main_window()

func _on_UnsavedChangesDialog_custom_action(action):
	if action == "no":
		_UnsavedChangesDialog.hide()
		WindowManager.show_main_window()
