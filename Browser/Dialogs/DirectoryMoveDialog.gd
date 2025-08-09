extends Window

signal refresh_ui()

const FOLDER_ICON = preload("res://Assets/Material Icons/folder.svg")

@onready var _Tree := $MarginContainer/VBoxContainer/Tree
@onready var _MoveButton := $MarginContainer/VBoxContainer/HBoxContainer/Move
@onready var _LinkButton := $MarginContainer/VBoxContainer/HBoxContainer/Link

var _Root : TreeItem
var _Selected : TreeItem

var _Dataset = null

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
	_Dataset = data
	if (_Dataset is Array) && _Dataset.size() == 1:
		_Dataset = _Dataset[0]
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
	
	if _Dataset is Array:
		_MoveButton.disabled = false
		_LinkButton.disabled = false
	else:
		var buttonDisabled : bool = (_Selected == null)
		if _Dataset is AMDirectory:
			buttonDisabled = buttonDisabled || (_Dataset.id == _Selected.get_metadata(0)) || (_Selected.get_metadata(0) == _Dataset.parent_id)
		else:
			buttonDisabled = buttonDisabled || (_Selected.get_metadata(0) == 0) || AssetsLibrary.is_asset_in_dir(_Dataset.id, _Selected.get_metadata(0))
		
		_MoveButton.disabled = buttonDisabled
		_LinkButton.disabled = (_Dataset is AMDirectory) || buttonDisabled

func _on_Move_pressed() -> void:
	if _Dataset is Array:
		AssetsLibrary.bulk_move(_Dataset, _Selected.get_metadata(0))
	else:
		AssetsLibrary.move(_Dataset, _Selected.get_metadata(0))
	
	emit_signal("refresh_ui")
	hide()

func _on_Link_pressed():
	if _Dataset is Array:
		AssetsLibrary.bulk_link(_Dataset, _Selected.get_metadata(0))
	else:
		AssetsLibrary.link_asset(_Dataset.id, _Selected.get_metadata(0))
	emit_signal("refresh_ui")
	hide()
