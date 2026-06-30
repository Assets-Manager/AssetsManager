# In this dialog the user can decide how a new asset that is marked as already 
# existing should be treated.
extends Window

const DEFAULT_ICON = preload("res://icon.png")

@onready var _NewAssets := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/NewAssets
@onready var _ExistingAssets := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ExistingAssets
@onready var _OverwriteBtn := $MarginContainer/VBoxContainer/HBoxContainer2/Overwrite 
@onready var _LinkBtn := $MarginContainer/VBoxContainer/HBoxContainer2/Link
@onready var _NewBtn := $MarginContainer/VBoxContainer/HBoxContainer2/New
@onready var _Search := $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/Search

var _ThumbnailThreads : Array[Thread] = []
var _ThumbnailRenderPos : int = 0

var _Selected : AMImportFile = null
var _SelectedExisting : AMAsset = null
var _ImportAssets : Array[AMImportFile] = []

# Sets the new asset infos
func set_new_assets(assets : Array[AMImportFile]) -> void:
	_ImportAssets = assets
	_Search.text = ""
	
	filter_new_assets()
	
	# Starts for each core a render thread.
	for i in OS.get_processor_count():
		var t = _start_thread()
		if t:
			_ThumbnailThreads.push_back(t)
		else:
			break
			
## Filters the new assets list
func filter_new_assets() -> void:
	_NewAssets.clear()
	_ExistingAssets.clear()
	_Selected = null
	_SelectedExisting = null
	_LinkBtn.visible = false
	for a in _ImportAssets:
		if _Search.text.is_empty() || a.file.get_file().containsn(_Search.text):
			a.set_meta("list_idx", _NewAssets.item_count)
			var icon = DEFAULT_ICON
			if a.has_meta("thumbnail"):
				icon = a.get_meta("thumbnail")
			
			_NewAssets.add_item(a.file.get_file(), icon)
			_NewAssets.set_item_metadata(_NewAssets.item_count - 1, a)
		else:
			a.remove_meta("list_idx")
	
func _process(_delta: float) -> void:
	# Are render threads running?
	# If so than check for finished ones.
	var running_threads : Array[Thread] = []
	for thread in _ThumbnailThreads:
		if !thread.is_alive():
			var file_thumbnail = thread.wait_to_finish()
			var file : AMImportFile = file_thumbnail["file"]
			file.set_meta("thumbnail", file_thumbnail["thumbnail"])
			var idx = file.get_meta("list_idx")
			if idx != null:
				_NewAssets.set_item_icon(idx, file_thumbnail["thumbnail"])
			var t = _start_thread()
			if t:
				running_threads.push_back(t)
		else:
			running_threads.push_back(thread)
	
	# Swap lists
	_ThumbnailThreads = running_threads
	
## Starts a new render thread
func _start_thread() -> Thread:
	if _ThumbnailRenderPos >= _ImportAssets.size():
		return null
	
	var thread := Thread.new()
	thread.start(_render_thumbnail.bind(_ImportAssets[_ThumbnailRenderPos]))
	_ThumbnailRenderPos += 1
	
	return thread
	
func _exit_tree() -> void:
	# Wait for the render threads to finish, before the programm is closed.
	for thread in _ThumbnailThreads:
		thread.wait_to_finish()

## Renders the thumbnail. Since some importers only work on the main thread,
## this one must be called outside of the main thread, to avoid locking.
## Returns a Dictionary {"file": AMImportFile, "thumbnail": Texture2D}
func _render_thumbnail(file: AMImportFile) -> Dictionary:
	return {
		"file": file,
		"thumbnail": file.importer.render_thumbnail(file.file)
	}

func _directory_id() -> int:
	if _Selected.parent_id != 0:
		return _Selected.parent_id
		
	return AssetsLibrary.current_directory

# Creates the asset as a new one.
func _on_New_pressed():
	_Selected.status = AssetsLibrary.FileImportStatus.STATUS_OK
	AssetsLibrary.handle_user_processed_file(_Selected)
	_on_assets_done()

func _on_Cancel_pressed():
	# Cleanup
	_Selected = null
	_SelectedExisting = null
	_NewBtn.disabled = true
	_OverwriteBtn.disabled = true
	_LinkBtn.disabled = true
	_ThumbnailRenderPos = 0
	_NewAssets.clear()
	_ExistingAssets.clear()
	
	hide()

# Overwrites a selected assets
func _on_Overwrite_pressed():
	_Selected.overwrite_id = _SelectedExisting.id
	AssetsLibrary.handle_user_processed_file(_Selected)
	_on_assets_done()

# Links the selected asset with the current directory.
func _on_Link_pressed():
	AssetsLibrary.move(_SelectedExisting, _directory_id(), true)
	BrowserManager.refresh_ui()
	_on_assets_done()

func _on_assets_done() -> void:
	_ExistingAssets.clear()
	_ImportAssets.erase(_Selected)
	_Selected = null
	_SelectedExisting = null
	_LinkBtn.disabled = true
	_OverwriteBtn.disabled = true
	
	if _ImportAssets.is_empty():
		_on_Cancel_pressed()
	else:
		filter_new_assets()

func _on_search_text_changed(_t: String) -> void:
	filter_new_assets()

func _on_new_assets_item_selected(index: int) -> void:
	_Selected = _NewAssets.get_item_metadata(index)
	_NewBtn.disabled = false
	_LinkBtn.visible = _directory_id() != 0
	_show_existing_assets()

func _show_existing_assets() -> void:
	_ExistingAssets.clear()
	
	## Gets a list with all assets, which shares the same name
	var assets: Array[AMAsset] = AssetsLibrary.get_assets_by_name(_Selected.file)
	for dbasset in assets:	# Add them to the dialog
		_ExistingAssets.add_item(dbasset.filename, AssetsLibrary.load_thumbnail(dbasset))
		_ExistingAssets.set_item_metadata(_ExistingAssets.item_count - 1, dbasset)
		
func _on_close_requested() -> void:
	_on_Cancel_pressed()

func _on_existing_assets_item_selected(index: int) -> void:
	_SelectedExisting = _ExistingAssets.get_item_metadata(index)
	_OverwriteBtn.disabled = false

	## Checks if the selected asset isn't already in the current directory.
	if _LinkBtn.visible:
		_LinkBtn.disabled = AssetsLibrary.is_asset_in_dir(_SelectedExisting.id, _directory_id())
