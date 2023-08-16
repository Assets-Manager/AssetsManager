extends CenterContainer

onready var _Recent := $VBoxContainer/Recent
onready var _NativeDialogs := $NativeDialogs
onready var _InfoDialog := $CanvasLayer/InfoDialog

func _ready():
	# Reopens the last loaded library.
	if !ProgramManager.settings.last_opened.empty():
		if AssetsLibrary.open(ProgramManager.settings.last_opened):
			get_tree().change_scene("res://Browser/Browser.tscn")
			return
	
	# Loads the recent libraries list
	for recent in ProgramManager.settings.recent_asset_libraries:
		_Recent.add_item(recent.get_file())
		_Recent.set_item_tooltip(_Recent.get_item_count() - 1, recent)

func _on_NewProject_pressed():
	var path : PoolStringArray = _NativeDialogs.show_modal()
	if !path.empty():
		_try_open_library(path[0], !_check_dir_is_empty(path[0]), "Directory must be empty!")

func _on_OpenProject_pressed():
	var path : PoolStringArray = _NativeDialogs.show_modal()
	var file : File = File.new()
	if !path.empty():
		_try_open_library(path[0], !file.file_exists(path[0] + "/assets.db"), "Not a valid asset library!")

# Tries to open the library or shows an error.
func _try_open_library(path: String, show_error : bool, error : String) -> void:
	if show_error:
		_InfoDialog.dialog_text = tr(error)
		_InfoDialog.popup_centered()
	else:
		if AssetsLibrary.open(path):	# Loads the library
			if ProgramManager.settings.recent_asset_libraries.find(path) == -1:
				ProgramManager.settings.recent_asset_libraries.append(path)
			get_tree().change_scene("res://Browser/Browser.tscn")
		else:
			_InfoDialog.dialog_text = tr("Failed to open library!")
			_InfoDialog.popup_centered()

func _check_dir_is_empty(path : String) -> bool:
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if (file_name != ".") && (file_name != ".."):
				return false
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		return false
		
	return true

func _on_Recent_item_selected(index):
	var file : File = File.new()
	_try_open_library(_Recent.get_item_tooltip(index), !file.file_exists(_Recent.get_item_tooltip(index) + "/assets.db"), "Not a valid asset library!")
