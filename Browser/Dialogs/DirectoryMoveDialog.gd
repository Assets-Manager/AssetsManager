extends WindowDialog

signal move_item(parent_id, id, is_dir)

const FOLDER_ICON = preload("res://Assets/Material Icons/folder.svg")

onready var _Tree := $MarginContainer/VBoxContainer/Tree
onready var _MoveButton := $MarginContainer/VBoxContainer/HBoxContainer/Move

var _Root : TreeItem
var _Selected : TreeItem

var _Id : int = -1
var _IsDir : bool = false

func _ready() -> void:
	_Root = _Tree.create_item()
	_Root.set_text(0, "root")
	_Root.set_metadata(0, 0)
	_Root.set_icon(0, FOLDER_ICON)
	_Root.set_icon_max_width(0, 24)
	
	get_close_button().hide()
	rect_size = rect_min_size
	
	get_viewport().connect("size_changed", self, "_size_changed")

func _size_changed() -> void:
	rect_position = get_viewport_rect().size * 0.5 - rect_size * 0.5

# Reloads the directories and shows the dialog.
func show_dialog(id : int, is_dir : bool) -> void:
	_Id = id
	_IsDir = is_dir
	_MoveButton.disabled = true
	
	while _Root.get_children():
		_Root.remove_child(_Root.get_children())
	
	var directories := AssetsLibrary.get_all_directories()
	var dirs : Dictionary = {null: _Root}
	
	# Builds the directory tree
	for dir in directories:
		if dirs.has(dir["parent_id"]):
			var newdir : TreeItem = _Tree.create_item(dirs[dir["parent_id"]])
			newdir.set_text(0, dir["name"])
			newdir.set_metadata(0, dir["id"])
			newdir.set_icon(0, FOLDER_ICON)
			newdir.set_icon_max_width(0, 24)
			dirs[dir["id"]] = newdir
		else:
			printerr("Dir doesn't exists: " + str(dir["parent_id"]))
			
	popup_centered()

func _on_Cancel_pressed() -> void:
	hide()

func _on_Tree_item_selected() -> void:
	_Selected = _Tree.get_selected()
	_MoveButton.disabled = _Selected == null

func _on_Move_pressed() -> void:
	emit_signal("move_item", _Selected.get_metadata(0), _Id, _IsDir)
	hide()
