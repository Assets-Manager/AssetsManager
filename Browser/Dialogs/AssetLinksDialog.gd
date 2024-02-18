extends WindowDialog

const FOLDER_ICON = preload("res://Assets/Material Icons/folder.svg")

onready var _Directories := $MarginContainer/VBoxContainer/Directories
onready var _Unlink := $MarginContainer/VBoxContainer/HBoxContainer/Unlink

var _SelectedDirectory : int = 0
var _SelectedIndex : int = 0
var _AssetId : int = 0

func set_asset_id(id : int) -> void:
	_AssetId = id
	_Unlink.disabled = true
	
	var dirs := AssetsLibrary.get_asset_linked_dirs(_AssetId)
	for dir in dirs:
		_Directories.add_item(dir.name, FOLDER_ICON)
		_Directories.set_item_metadata(_Directories.get_item_count() - 1, dir.id)

func _reset() -> void:
	_SelectedDirectory = 0
	_SelectedIndex = 0
	_Unlink.disabled = true

func _on_Cancel_pressed():
	_Directories.clear()
	_reset()
	hide()

func _on_Unlink_pressed():
	AssetsLibrary.unlink_asset(_SelectedDirectory, _AssetId)
	_Directories.remove_item(_SelectedIndex)
	_reset()
	
	if _Directories.get_item_count() == 0:
		_on_Cancel_pressed()

func _on_Directories_item_selected(index):
	_SelectedIndex = index
	_SelectedDirectory = _Directories.get_item_metadata(index)
	_Unlink.disabled = false
