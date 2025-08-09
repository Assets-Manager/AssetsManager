extends CenterContainer

@onready var _Recent := $VBoxContainer/ScrollContainer/Recent
@onready var _NativeDialogs : FileDialog = $NativeDialogs
@onready var _InfoDialog := $CanvasLayer/InfoDialog
@onready var _DisclaimerDialog := $CanvasLayer/DisclaimerDialog
@onready var _GodotTour := $CanvasLayer/GodotTour

func _ready():
	if !ProgramManager.settings.disclaimer_accepted:
		_DisclaimerDialog.hide()
		_DisclaimerDialog.force_native = true
		_DisclaimerDialog.popup_centered()
	
	# Reopens the last loaded library.
	if !ProgramManager.settings.last_opened.is_empty():
		if AssetsLibrary.open(ProgramManager.settings.last_opened):
			call_deferred("_switch_scene")
			return
	
	# Loads the recent libraries list
	for recent in ProgramManager.settings.recent_asset_libraries:
		var tmp := LinkButton.new()
		tmp.text = recent.get_file()
		tmp.tooltip_text = recent
		tmp.add_theme_color_override("font_color", Color("#6e9dff"))
		tmp.connect("pressed", Callable(self, "_open_recent").bind(recent))
		_Recent.add_child(tmp)
		
	call_deferred("_start_tour")

func _switch_scene() -> void:
	get_tree().change_scene_to_file("res://Browser/Browser.tscn")

func _start_tour():
	if ProgramManager.settings.disclaimer_accepted and (ProgramManager.settings.tutorial_step < ProgramManager.settings.TutorialStep.LIBRARY_SCREEN):
		_GodotTour.visible = true
		_GodotTour.start()
	else:
		_GodotTour.visible = false

func _on_NewProject_pressed():
	_NativeDialogs.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_NativeDialogs.popup_centered()
	var path : String = await _NativeDialogs.dir_selected
	if !path.is_empty():
		_try_open_library(path, !_check_dir_is_empty(path), "Dir must be empty!")

func _on_OpenProject_pressed():
	_NativeDialogs.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_NativeDialogs.popup_centered()
	var path : String = await _NativeDialogs.dir_selected
	if !path.is_empty():
		_try_open_library(path, !FileAccess.file_exists(path.path_join("assets.db")), "Not a valid asset library!")

# Tries to open the library or shows an error.
func _try_open_library(path: String, show_error : bool, error : String) -> void:
	if show_error:
		_InfoDialog.dialog_text = tr(error)
		_InfoDialog.popup_centered()
	else:
		if AssetsLibrary.open(path):	# Loads the library
			if ProgramManager.settings.recent_asset_libraries.find(path) == -1:
				ProgramManager.settings.recent_asset_libraries.append(path)
			get_tree().change_scene_to_file("res://Browser/Browser.tscn")
		else:
			_InfoDialog.dialog_text = tr("Failed to open library!")
			_InfoDialog.popup_centered()

func _check_dir_is_empty(path : String) -> bool:
	var dir = DirAccess.open(path)
	if dir:
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

func _open_recent(path: String):
	_try_open_library(path, !FileAccess.file_exists(path.path_join("assets.db")), "Not a valid asset library!")

func _on_DisclaimerDialog_popup_hide():
	_start_tour()

func _on_GodotTour_tour_finished():
	ProgramManager.settings.tutorial_step = ProgramManager.settings.TutorialStep.LIBRARY_SCREEN
