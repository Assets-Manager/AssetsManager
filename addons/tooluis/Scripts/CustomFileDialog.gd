class_name CustomFileDialog
extends WindowDialog

signal file_selected(file)
signal files_selected(files)

enum Mode {
	MODE_OPEN_FILE = 0,
	MODE_OPEN_FILES = 1,
	MODE_OPEN_DIR = 2,
	MODE_OPEN_ANY = 3,
	MODE_SAVE_FILE = 4
}

enum Access {
	ACCESS_RESOURCES = 0,
	ACCESS_USERDATA = 1,
	ACCESS_FILESYSTEM = 2
}

export(bool) var allow_select_all_files = true
export(Mode) var mode = Mode.MODE_OPEN_ANY setget set_mode
export(Access) var access = Access.ACCESS_RESOURCES setget set_access
export(PoolStringArray) var filters : PoolStringArray = [] setget set_filters
export(bool) var show_hidden_files = false
export(String) var current_dir = "" setget set_current_dir
export(PoolStringArray) var favourites setget set_favourites
export(PoolStringArray) var recent setget set_recent

onready var _Path := $VBoxContainer/HBoxContainer2/Path
onready var _Favourites := $VBoxContainer/HBoxContainer/SpecialFolders/Favourites
onready var _System := $VBoxContainer/HBoxContainer/SpecialFolders/System
onready var _Recent := $VBoxContainer/HBoxContainer/SpecialFolders/Recent
onready var _Files := $VBoxContainer/HBoxContainer/VBoxContainer2/Files
onready var _File := $VBoxContainer/HBoxContainer/VBoxContainer2/HBoxContainer/File
onready var _Filters := $VBoxContainer/HBoxContainer/VBoxContainer2/HBoxContainer/Filters
onready var _Positive := $VBoxContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/Positive
onready var _Back := $VBoxContainer/HBoxContainer2/Back
onready var _Forward := $VBoxContainer/HBoxContainer2/Forward
onready var _Up := $VBoxContainer/HBoxContainer2/Up
onready var _Refresh := $VBoxContainer/HBoxContainer2/Refresh
onready var _SpecialFolders := $VBoxContainer/HBoxContainer/SpecialFolders
onready var _NothingSelected := $NothingSelected
onready var _OverrideDLG := $OverrideDLG
onready var _Fav := $VBoxContainer/HBoxContainer2/Fav
onready var _ShowHidden = $VBoxContainer/HBoxContainer2/ShowHidden
onready var _DeleteFavDLG := $DeleteFavDLG
onready var _AddFolder := $VBoxContainer/HBoxContainer2/AddFolder
onready var _NewFolderDLG := $NewFolderDLG
onready var _FolderName := $NewFolderDLG/MarginContainer/VBoxContainer/FolderName
onready var _Popup := $PopupMenu

var _AllSupported = ""
var _History = []
var _HistoryPos = -1
var _SupportedExts = {}

func _ready() -> void:
	_Up.icon = get_icon("parent_folder", "FileDialog")
	_Refresh.icon = get_icon("reload", "FileDialog")
	_ShowHidden.icon = get_icon("toggle_hidden", "FileDialog")
	_Fav.icon = get_icon("fav_icon", "CustomFileDialog")
	_Back.icon = get_icon("back_icon", "CustomFileDialog")
	_Forward.icon = get_icon("forward_icon", "CustomFileDialog")
	_AddFolder.icon = get_icon("add_folder_icon", "CustomFileDialog")
	_Popup.add_item("New folder")
	
	_OverrideDLG.get_ok().text = tr("Yes")
	_OverrideDLG.get_cancel().text = tr("No")

	_update_filters_gui()
	_update_path_gui()
	_update_special_folders_visibility()
	_update_history_gui()
	_update_files_selection_mode()
	_update_favourites_gui()
	_update_recent_gui()

func set_favourites(val : PoolStringArray) -> void:
	favourites = val
	
	if _Favourites:
		_update_favourites_gui()
	
func set_recent(val : PoolStringArray) -> void:
	recent = val
	
	if _Recent:
		_update_recent_gui()

func set_mode(val) -> void:
	mode = val
	
	if _Files:
		_update_files_selection_mode()

func set_access(val) -> void:
	access = val
	
	if _SpecialFolders:
		_update_special_folders_visibility()
		_set_default_current_dir()
		_update_path_gui()
		
func _update_favourites_gui() -> void:
	_Favourites.clear()
	
	for fav in favourites:
		if fav[fav.length() - 1] == "/":
			fav.erase(fav.length() - 1, 1)
		
		_Favourites.add_item(fav.get_file(), get_icon("folder", "FileDialog"))
		_Favourites.set_item_tooltip(_Favourites.get_item_count() - 1, fav)
		_Favourites.set_item_metadata(_Favourites.get_item_count() - 1, fav)
	
func _update_recent_gui() -> void:
	_Recent.clear()
	
	for rec in recent:
		_Recent.add_item(rec.get_file(), get_icon("folder", "FileDialog"))
		_Recent.set_item_tooltip(_Recent.get_item_count() - 1, rec)
		_Recent.set_item_metadata(_Recent.get_item_count() - 1, rec)
	
func _update_files_selection_mode() -> void:
	if mode == Mode.MODE_OPEN_FILES:
		_Files.select_mode = Tree.SELECT_MULTI
	else:
		_Files.select_mode = Tree.SELECT_SINGLE
		
	if mode == Mode.MODE_SAVE_FILE:
		_AddFolder.visible = true
	else:
		_AddFolder.visible = false
		
	match mode:
		Mode.MODE_SAVE_FILE:
			_Positive.text = "Save"
			window_title = "Save a File"
			
		Mode.MODE_OPEN_ANY:
			_Positive.text = "Open"
			window_title = "Open a File or Directory"
		
		Mode.MODE_OPEN_FILE:
			_Positive.text = "Open"
			window_title = "Open a File"
			
		Mode.MODE_OPEN_FILES:
			_Positive.text = "Open"
			window_title = "Open File(s)"
			
		Mode.MODE_OPEN_DIR:
			_Positive.text = "Open"
			window_title = "Open a Directory"
	
func _update_history_gui(disable_back : bool = false) -> void:
	_Back.disabled = _HistoryPos == -1 || disable_back
	_Forward.disabled = _HistoryPos == (_History.size() - 1)

func _update_special_folders_visibility():
	if access != Access.ACCESS_FILESYSTEM:
		_SpecialFolders.visible = false
	else:
		_SpecialFolders.visible = true
		_System.clear()
		var dirIcon : Texture = get_icon("folder", "FileDialog")
				
		for i in range(OS.SYSTEM_DIR_DESKTOP, OS.SYSTEM_DIR_RINGTONES):
			var path = OS.get_system_dir(i)
			_System.add_item(path.get_file(), dirIcon)
			_System.set_item_tooltip(_System.get_item_count() - 1, path)
			_System.set_item_metadata(_System.get_item_count() - 1, path)
		
func _set_default_current_dir() -> void:
	match access:
		Access.ACCESS_FILESYSTEM:
			current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		Access.ACCESS_RESOURCES:
			current_dir = "res://"
		Access.ACCESS_USERDATA:
			current_dir = "user://"

func set_current_dir(val : String) -> void:
	if !val.empty() && val[val.length() - 1] == "/":
		val = val.substr(0, val.length() - 1)
	
	current_dir = val
	
	if _Path:
		_update_path_gui()

func set_filters(val : PoolStringArray) -> void:	
	_AllSupported = ""
	filters = []
	_SupportedExts = {}
	
	for filter in val:
		if _AllSupported != "":
			_AllSupported += ", "
		
		var splitfilter = filter.split(";", false)
		_AllSupported += splitfilter[0].strip_edges()
		_SupportedExts[splitfilter[0].strip_edges()] = null
	
	if allow_select_all_files:
		filters.push_back("*.*; All files")
		
	filters.append_array(val)
	
	if _Filters:
		_update_filters_gui()

func _update_filters_gui() -> void:
	_Filters.clear()
	
	_Filters.add_item(tr("All supported types"))#"%s (%s)" % [tr("All supported types"), _AllSupported.substr(0, 30)])
	_Filters.set_item_metadata(_Filters.get_item_count() - 1, _SupportedExts)
	
	for filter in filters:
		var splitfilter = filter.split(";", false)
		_Filters.add_item("%s (%s)" % [tr(splitfilter[1].strip_edges()), splitfilter[0].strip_edges()])
		_Filters.set_item_metadata(_Filters.get_item_count() - 1, splitfilter[0].strip_edges())

func _update_path_gui() -> void:
	if current_dir == "":
		_set_default_current_dir()
		
	_Path.text = current_dir
	_list_files()

func _list_files() -> void:	
	var dirIcon : Texture = get_icon("folder", "FileDialog")
	var fileIcon : Texture = get_icon("file", "FileDialog")
	
	_Files.clear()
	_Files.set_column_titles_visible(true)
	_Files.set_column_title(0, "Name")
	var root = _Files.create_item()
	
	var dir := Directory.new()
	if dir.open(current_dir) == OK:
		var ext = _Filters.get_selected_metadata()
		
		dir.list_dir_begin(true, !show_hidden_files)
		var filename = dir.get_next()
		while filename != "":
			if dir.current_is_dir():
				var item = _Files.create_item(root)
				item.set_text(0, filename)
				item.set_icon(0, dirIcon)
				
				#_Files.add_item(filename, dirIcon)
			elif mode != Mode.MODE_OPEN_DIR:
				var add_file = false
				
				if ext is Dictionary:
					 add_file = _SupportedExts.has("*." + filename.get_extension())
				else:
					add_file = ext == ("*." + filename.get_extension()) || ext == "*.*"
				
				if add_file:
					var item = _Files.create_item(root)
					item.set_text(0, filename)
					item.set_icon(0, fileIcon)
					
					#_Files.add_item(filename, fileIcon)
				
			filename = dir.get_next()
		dir.list_dir_end()

func _on_filters_item_selected(index: int) -> void:
	if index > 1:
		var filter := filters[index - 1]
		var splitfilter := filter.split(";", false)
		
		var ext : String = splitfilter[0].strip_edges().substr(1)
		_File.text = _File.text.get_basename() + ext
		
	_list_files()

func _on_files_item_activated() -> void:
	var name : String = _Files.get_selected().get_text(0)
	
	var fullpath = _get_fullpath(name)
	
	var dir := Directory.new()
	if dir.dir_exists(fullpath):
		set_current_dir(fullpath)
		_add_to_history()
	elif dir.file_exists(fullpath):
		_File.text = name
		_on_positive_pressed()

func _on_folder_up_pressed() -> void:
	var parent_dir = _Path.text.get_base_dir()
	if parent_dir != current_dir:
		set_current_dir(parent_dir)

func _on_refresh_pressed() -> void:
	_list_files()

func _on_Path_text_entered(new_text: String) -> void:
	var dir := Directory.new()
	
	var dont_change_dir = false
	
	match access:
		Access.ACCESS_USERDATA:
			dont_change_dir = !_Path.text.begins_with("user://")
		Access.ACCESS_RESOURCES:
			dont_change_dir = !_Path.text.begins_with("res://")
		Access.ACCESS_FILESYSTEM:
			dont_change_dir = _Path.text.begins_with("res://") || _Path.text.begins_with("user://")
	
	if !dir.dir_exists(new_text) || dont_change_dir:
		_Path.text = current_dir
	else:
		_add_to_history(false)
		set_current_dir(_Path.text)

func _add_to_history(remove_dir : bool = true) -> void:
	if _HistoryPos != (_History.size() - 1) and _HistoryPos != -1:
		_History = _History.slice(0, _HistoryPos)
	elif _HistoryPos == -1:
		_History = []
		
	var path = ""
	var add_path = true
	
	if remove_dir:
		path = current_dir.get_base_dir()
	else:
		path = current_dir
		
	if !_History.empty():
		add_path = _History[_History.size() - 1] != path
		
	if add_path:
		_History.push_back(path)
		_HistoryPos += 1
	
	_update_history_gui()

func _on_forward_pressed() -> void:
	_HistoryPos += 1
	set_current_dir(_History[_HistoryPos])
	
	if _HistoryPos == (_History.size() - 1):
		_History.remove(_HistoryPos)
		_HistoryPos -= 1
	
	_update_history_gui()

func _on_back_pressed() -> void:
	if _HistoryPos == (_History.size() - 1):
		_add_to_history(false)
		
	_HistoryPos -= 1
	set_current_dir(_History[_HistoryPos])
	
	_update_history_gui(_HistoryPos == 0)

func _on_files_item_selected() -> void:
	var name : String = _Files.get_selected().get_text(0)
	
	var fullpath = _get_fullpath(name)
	
	var dir := Directory.new()
	if dir.dir_exists(fullpath) and (mode == Mode.MODE_OPEN_ANY or mode == Mode.MODE_OPEN_DIR):
		_File.text = name
	elif dir.file_exists(fullpath) and (mode != Mode.MODE_OPEN_DIR):
		_File.text = name

func _on_files_multi_selected(item : TreeItem, column : int, selected : bool) -> void:
	var dir := Directory.new()

	_File.text = ""
	
	item = _Files.get_next_selected(null)
	while item:
		var name : String = item.get_text(0)
		
		var fullpath = _get_fullpath(name)
		
		if dir.file_exists(fullpath):
			if _File.text != "":
				_File.text += "; "
			_File.text += name
	
		item = _Files.get_next_selected(item)

func _on_cancel_pressed() -> void:
	hide()

func _get_fullpath(file : String) -> String:
	var fullpath = current_dir
	if fullpath[fullpath.length() - 1] != "/":
		fullpath += "/"
	fullpath += file
	
	return fullpath

func _on_positive_pressed() -> void:
	if _Path.text == "" || _File.text == "":
		_NothingSelected.dialog_text = "Please select a File"
		_NothingSelected.popup_centered()
	else:
		match mode:
			Mode.MODE_OPEN_FILES:
				var files = _File.text.split(";")
				var dir := Directory.new()
				var paths = []
				
				var files_checked = true
				
				for filename in files:
					var fullpath = _get_fullpath(filename.strip_edges())
					
					if !dir.file_exists(fullpath):
						_NothingSelected.dialog_text = tr("File not found: ") + filename
						_NothingSelected.popup_centered()
						files_checked = false
						break
					else:
						paths.push_back(fullpath)
						
				if files_checked:
					_add_to_recent(paths)
					
					emit_signal("files_selected", paths)
					hide()
					
			Mode.MODE_SAVE_FILE:
				var dir := Directory.new()
				var fullpath = _get_fullpath(_File.text.strip_edges())
				if dir.file_exists(fullpath):
					_OverrideDLG.popup_centered()
				else:
					_add_to_recent([fullpath])
					emit_signal("file_selected", fullpath)
					hide()
			
			_:
				var dir := Directory.new()
				var fullpath = _get_fullpath(_File.text.strip_edges())
				if dir.file_exists(fullpath) or dir.dir_exists(fullpath):
					_add_to_recent([fullpath])
					emit_signal("file_selected", fullpath)
					hide()
				else:
					_NothingSelected.dialog_text = tr("File not found: ") + _File.text
					_NothingSelected.popup_centered()

func _on_override_confirmed() -> void:
	var fullpath = _get_fullpath(_File.text.strip_edges())
	_add_to_recent([fullpath])
	emit_signal("file_selected", fullpath)
	hide()

func _on_fav_pressed() -> void:
	var found = false
	for fav in favourites:
		if fav == current_dir:
			found = true
			break

	if !found:
		favourites.push_back(current_dir)
		
		_Favourites.add_item(current_dir.get_file(), get_icon("folder", "FileDialog"))
		_Favourites.set_item_tooltip(_Favourites.get_item_count() - 1, current_dir)
		_Favourites.set_item_metadata(_Favourites.get_item_count() - 1, current_dir)

func _on_favourites_item_activated(index: int) -> void:
	_add_to_history(false)
	set_current_dir(_Favourites.get_item_metadata(index))

func _on_ShowHidden_toggled(button_pressed: bool) -> void:
	show_hidden_files = button_pressed
	_list_files()
	
func _on_system_item_selected(index: int) -> void:
	_add_to_history(false)
	set_current_dir(_System.get_item_metadata(index))

func _on_favourites_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and !_Favourites.get_selected_items().empty():
		if event.scancode == KEY_DELETE and event.pressed:
			_DeleteFavDLG.popup_centered()

func _on_delete_fav_confirmed() -> void:
	if !_Favourites.get_selected_items().empty():
		favourites.remove(_Favourites.get_selected_items()[0])
		_Favourites.remove_item(_Favourites.get_selected_items()[0])

func _on_recent_item_activated(index: int) -> void:
	var file : String = _Recent.get_item_metadata(index)
	set_current_dir(file.get_base_dir())
	_File.text = file.get_file()
	_on_positive_pressed()

func _on_addfolder_pressed(id) -> void:
	_FolderName.text = ""
	_NewFolderDLG.popup_centered()

func _on_new_folder_cancel_pressed() -> void:
	_NewFolderDLG.hide()

func _on_new_folde_ok_pressed() -> void:
	if _FolderName.text != "":
		var dir = Directory.new()
		dir.make_dir(current_dir + "/" + _FolderName.text)
		_list_files()
	
	_NewFolderDLG.hide()

func _on_files_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and mode == Mode.MODE_SAVE_FILE:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			_Popup.popup(Rect2(event.global_position, Vector2(120, 20)))

func _on_foldername_text_entered(new_text: String) -> void:
	_on_new_folde_ok_pressed()

func _on_File_text_entered(new_text: String) -> void:
	_on_positive_pressed()

func _add_to_recent(paths) -> void:
	for path in paths:
		if !recent.has(path):
			recent.append(path)
