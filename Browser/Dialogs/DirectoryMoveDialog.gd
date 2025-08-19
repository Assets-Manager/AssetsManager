extends Window

const FOLDER_ICON = preload("res://Assets/Material Icons/folder.svg")

@onready var _Tree := $MarginContainer/VBoxContainer/Tree
@onready var _MoveButton := $MarginContainer/VBoxContainer/HBoxContainer/Move
@onready var _LinkButton := $MarginContainer/VBoxContainer/HBoxContainer/Link

var _Root : TreeItem
var _Selected : TreeItem

var _asset = null

func _ready() -> void:
	_Root = _Tree.create_item()
	_Root.set_text(0, "root")
	_Root.set_metadata(0, 0)
	_Root.set_icon(0, FOLDER_ICON)
	_Root.set_icon_max_width(0, 24)
	
	#size = custom_minimum_size
	get_tree().get_root().get_viewport().size_changed.connect(_size_changed)

func _size_changed() -> void:
	position = get_tree().get_root().get_viewport().size * 0.5 - size * 0.5

# Reloads the directories and shows the dialog.
func show_dialog(data) -> void:
	_asset = data
	if (_asset is Array) && _asset.size() == 1:
		_asset = _asset[0]
	_MoveButton.disabled = true
	_LinkButton.disabled = true
	
	while _Root.get_child_count():
		_Root.remove_child(_Root.get_child(0))
	
	var directories := AssetsLibrary.get_all_directories()
	var dirs : Dictionary[int, TreeItem] = {0: _Root}
	var parentDirs : PackedInt32Array = []
	if data is Array:
		for d in data:
			if d is AMDirectory:
				parentDirs.append(d.id)
	else:
		if data is AMDirectory:
			parentDirs.append(data.id)
	
	# Builds the directory tree
	for dir in directories:
		if parentDirs.find(dir.parent_id) != -1:
			continue
		
		if dirs.has(dir.parent_id):
			var newdir : TreeItem = _Tree.create_item(dirs[dir.parent_id])
			newdir.set_text(0, dir.name)
			newdir.set_metadata(0, dir.id)
			newdir.set_icon(0, FOLDER_ICON)
			newdir.set_icon_max_width(0, 24)
			dirs[dir.id] = newdir
			
	popup_centered()

func _on_Cancel_pressed() -> void:
	hide()

func _on_Tree_item_selected() -> void:
	_Selected = _Tree.get_selected()
	
	if _asset is Array:
		_MoveButton.disabled = false
		_LinkButton.disabled = false
	else:
		var buttonDisabled : bool = (_Selected == null)
		if _asset is AMDirectory:
			buttonDisabled = buttonDisabled || (_asset.id == _Selected.get_metadata(0)) || (_Selected.get_metadata(0) == _asset.parent_id)
		else:
			buttonDisabled = buttonDisabled || (_Selected.get_metadata(0) == 0) || AssetsLibrary.is_asset_in_dir(_asset.id, _Selected.get_metadata(0))
		
		_MoveButton.disabled = buttonDisabled
		_LinkButton.disabled = (_asset is AMDirectory) || buttonDisabled

func _on_Move_pressed() -> void:
	AssetsLibrary.move(_asset, _Selected.get_metadata(0), false)
	BrowserManager.refresh_ui()
	hide()

func _on_Link_pressed():
	AssetsLibrary.move(_asset, _Selected.get_metadata(0), true)
	BrowserManager.refresh_ui()
	hide()
