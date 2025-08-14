extends HBoxContainer

const ASSET_CARD = preload("res://Browser/AssetCard.tscn")
const ITEMS_PER_PAGE : int = 100

@onready var _Cards := $Browser/ScrollContainer/CenterContainer/Cards
@onready var _ImporterDialog := $CanvasLayer/ImporterDialog
@onready var _DirectoryMoveDialog := $CanvasLayer/DirectoryMoveDialog
@onready var _Pagination := $Browser/MarginContainer2/HBoxContainer/Pagination
@onready var _Search := $Browser/MarginContainer/HBoxContainer/Search
@onready var _InputBox := $CanvasLayer/InputBox
@onready var _ScrollContainer := $Browser/ScrollContainer
@onready var _BackButton := $Browser/MarginContainer/HBoxContainer/Back
@onready var _HomeButton := $Browser/MarginContainer/HBoxContainer/Home
@onready var _DeleteDirDialog := $CanvasLayer/DeleteDirDialog
@onready var _NativeDialog : FileDialog = $NativeDialog
@onready var _InfoDialog := $CanvasLayer/InfoDialog
@onready var _GodotTour := $CanvasLayer/GodotTour
@onready var _OverwriteDialog := $CanvasLayer/OverwriteDialog
@onready var _AssetLinksDialog := $CanvasLayer/AssetLinksDialog
@onready var _SidePanel := $SidePanel

@onready var _AdvancedFilter := $Browser/MarginContainer/HBoxContainer/AdvancedFilter
@onready var _CloseLib := $Browser/MarginContainer2/HBoxContainer/CloseLib
@onready var _CreateDir := $Browser/MarginContainer/HBoxContainer/CreateDir

var _DirectoriesToDelete : Array[AMDirectory] = []
var _VisibleCards : int = 0
var _FilesToApprove : Array[Dictionary] = []

var _Thumbnail : Texture2D = null
var _ThumbnailThread : Thread = null

func _ready() -> void:
	# Connects all events of the library.
	AssetsLibrary.connect("update_total_import_assets", Callable(self, "_update_total_import_assets"))
	AssetsLibrary.connect("files_to_check", Callable(self, "_files_to_check"))
	
	# IMPORTANT: These MUST be called deferred, since this signals are emitted inside a thread.
	AssetsLibrary.connect("new_asset_added", Callable(self, "_new_asset_added").bind(), CONNECT_DEFERRED)
	AssetsLibrary.connect("increase_import_counter", Callable(self, "_increase_import_counter").bind(), CONNECT_DEFERRED)
	
	BrowserManager.search_changed.connect(_search_changed)
	BrowserManager.need_ui_refresh.connect(_on_refresh_ui)
	BrowserManager.show_file_info_signal.connect(_show_file_info)
	
	BrowserManager.enter_tagging_mode.connect(_enter_tagging_mode)
	BrowserManager.leave_tagging_mode.connect(_leave_tagging_mode)
	
	BrowserManager.reset_search()
	
	# Updates the initial pagination
	_search_changed()
	
	call_deferred("_start_tour")
	
func _enter_tagging_mode() -> void:
	_Pagination.disable_navigation(true)
	_BackButton.disabled = true
	_HomeButton.disabled = true
	_AdvancedFilter.disabled = true
	_Search.editable = false
	_CloseLib.disabled = true
	_CreateDir.disabled = true
	
func _leave_tagging_mode() -> void:
	_Pagination.disable_navigation(false)
	_AdvancedFilter.disabled = false
	_Search.editable = true
	_CloseLib.disabled = false
	_CreateDir.disabled = false
	
	_BackButton.disabled = AssetsLibrary.current_directory == 0
	_HomeButton.disabled = _BackButton.disabled
	
func _search_changed() -> void:
	_Pagination.total_pages = ceil(AssetsLibrary.get_assets_count(BrowserManager.search) / float(ITEMS_PER_PAGE))
	
func _start_tour() -> void:
	# Does the user already did the tutorial?
	if ProgramManager.settings.tutorial_step < ProgramManager.settings.TutorialStep.BROWSER_SCREEN:
		_GodotTour.visible = true
		_GodotTour.start()
	else:
		_GodotTour.visible = false

# ---------------------------------------------
# 			   UI import update
# ---------------------------------------------

func _process(_delta):
	# Is a render thread running?
	# If so than wait for it to finish.
	if _ThumbnailThread && !_ThumbnailThread.is_alive():
		_Thumbnail = _ThumbnailThread.wait_to_finish()
		_ThumbnailThread = null
	elif !_ThumbnailThread && !_ImporterDialog.visible && !_FilesToApprove.is_empty() && \
		 !_OverwriteDialog.visible:
		var file : Dictionary = _FilesToApprove.back()
		match file.status:
			AssetsLibrary.FileImportStatus.STATUS_OVERWRITE:
				# Starts a new render thread, if there is currently no thumnail available.
				if !_Thumbnail:
					_ThumbnailThread = Thread.new()
					_ThumbnailThread.start(Callable(self, "_render_thumbnail").bind(file))
				else:
					# Sets the newly dropped asset for the dialog
					_FilesToApprove.pop_back() # This is faster than pop_front
					_OverwriteDialog.set_new_asset(_Thumbnail, file)
					_OverwriteDialog.popup_centered()
					_Thumbnail = null

# Renders the thumbnail. Since some importers only work on the main thread,
# this one must be called outside of the main thread, to avoid locking.
func _render_thumbnail(file) -> Texture2D:
	return file.importer.render_thumbnail(file.file)

func _exit_tree() -> void:
	BrowserManager.search_changed.disconnect(_search_changed)
	BrowserManager.need_ui_refresh.disconnect(_on_refresh_ui)
	BrowserManager.show_file_info_signal.disconnect(_show_file_info)
	BrowserManager.enter_tagging_mode.disconnect(_enter_tagging_mode)
	BrowserManager.leave_tagging_mode.disconnect(_leave_tagging_mode)
	
	# Wait for the renderthread to finish, before the programm is closed.
	if _ThumbnailThread:
		_ThumbnailThread.wait_to_finish()

# Called if new assets needs to be imported
# Shows and updates the importer dialog and its progress bar max items.
func _update_total_import_assets(total_files : int) -> void:
	_ImporterDialog.set_total_files(total_files)
	
	# Shows the dialog and resets the progress, if the dialog is not already visisble.
	if !_ImporterDialog.visible:
		_ImporterDialog.set_value(0)
		_ImporterDialog.popup_centered()

# Called everytime an asset file is either a duplicate
# or is dropped into a new folder.
func _files_to_check(files: Array[Dictionary]) -> void:
	_FilesToApprove.append_array(files)

# Called if a new assets were successfully imported
# Updates the progressbar of the importer dialog.
func _new_asset_added(asset: AMAsset) -> void:
	# Only add a new card to the gui, if the max items per page isn't reached.
	if (_Cards.get_child_count() < ITEMS_PER_PAGE) || (_VisibleCards < _Cards.get_child_count()):
		var tmp: AssetCard = null
		
		# Checks if a card needs to be updated
		for child in _Cards.get_children():
			if !(child is AssetCard) || !child.visible:
				break
				
			if child.dataset.id == asset.id:
				tmp = child
				break
		
		if !tmp:
			if _Cards.get_child_count() < ITEMS_PER_PAGE:
				tmp = _create_card()
				_Cards.add_child(tmp)
			elif _VisibleCards < _Cards.get_child_count():
				tmp = _Cards.get_child(_VisibleCards)
			
		tmp.set_parent_folder(AssetsLibrary.current_directory)
		tmp.dataset = asset
		tmp.visible = true
		_VisibleCards += 1
	else:
		_search_changed()
	
	_increase_import_counter()

# Updates the progressbar
func _increase_import_counter() -> void:
	_ImporterDialog.increment_value()
	_on_Pagination_page_update(_Pagination.current_page)
	
	# If all files are imported, the dialog will be closed.
	if _ImporterDialog.get_value() == _ImporterDialog.get_total_files():
		_ImporterDialog.hide()

# ---------------------------------------------
# 			    Pagination
# ---------------------------------------------

# Always called if the page index changed of the pagination.
# Either by the user or by the pagination itself, if the total page count changes.
func _on_Pagination_page_update(page : int) -> void:
	if _Cards:		# In the initialization phase the container for the cards can be null.
		# Reset the scroll container, if the page is changed.
		_ScrollContainer.scroll_vertical = 0
		_ScrollContainer.scroll_horizontal = 0
		
		var cards := AssetsLibrary.query_assets(BrowserManager.search, (page - 1) * ITEMS_PER_PAGE, ITEMS_PER_PAGE)
		
		# Hide all card, which are currently visible, since we reuse them later.
		for child in _Cards.get_children():
			child.hide()
		
		# Reuse counter.
		_VisibleCards = 0
		for card in cards:
			var tmp: AssetCard = null
			
			# Creates or reuses a card element.
			if _VisibleCards >= _Cards.get_child_count():
				tmp = _create_card()
				_Cards.add_child(tmp)
			else:
				tmp = _Cards.get_child(_VisibleCards)
				tmp.visible = true
			
			_VisibleCards += 1
			
			# Sets the parent folder id.
			# So the user can open the containing folder of an asset.
			tmp.set_parent_folder(card.parent_id)
			
			# Fill the needed informations for a card.
			tmp.dataset = card

# ---------------------------------------------
# 			    Card signals
# ---------------------------------------------

func _move_to_directory_pressed(datasets: Array) -> void:
	_DirectoryMoveDialog.show_dialog(datasets)
	
func _show_links(id: int) -> void:
	_AssetLinksDialog.set_asset_id(id)
	_AssetLinksDialog.popup_centered()
	
func _card_pressed(data, is_dir : bool) -> void:
	# Opens the pressed directory.
	if is_dir:
		BrowserManager.deselect_all()
		
		AssetsLibrary.current_directory = data.id if data is AMDirectory else data
		BrowserManager.update_search({"directory_id": data.id if data is AMDirectory else data})

		_BackButton.mouse_default_cursor_shape = Control.CURSOR_ARROW if (AssetsLibrary.current_directory == 0) else Control.CURSOR_POINTING_HAND
		_HomeButton.mouse_default_cursor_shape = _BackButton.mouse_default_cursor_shape
		_BackButton.disabled = AssetsLibrary.current_directory == 0
		_HomeButton.disabled = _BackButton.disabled
	else:
		_show_file_info(data)

func _show_file_info(asset) -> void:
	if _SidePanel.is_open():
		_SidePanel.create_instance("FILEINFO").asset = asset
	else:
		_SidePanel.show_view("FILEINFO").asset = asset

# Exports an asset
func _export_assets(datasets: Array) -> void:
	if datasets.is_empty():
		return
	
	if (datasets.size() > 1) || (datasets[0] is AMDirectory):
		_NativeDialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	else:
		_NativeDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	
	var path : String = ""
	_NativeDialog.popup_centered()
	if (datasets.size() > 1) || (datasets[0] is AMDirectory):
		path = await _NativeDialog.dir_selected
	else:
		path = await _NativeDialog.file_selected
	
	if !path.is_empty():
		AssetsLibrary.export_assets(datasets, path)

func _delete_card(dirs: Array[AMDirectory]) -> void:
	_DirectoriesToDelete = dirs
	_DeleteDirDialog.popup_centered()

func _on_refresh_ui():
	var dir := AMDirectory.new()
	dir.id = AssetsLibrary.current_directory
	
	_card_pressed(dir, true)

# ---------------------------------------------
# 	   Different ui actions and functions
# ---------------------------------------------

# Creates a new card object.
func _create_card() -> AssetCard:
	var card : AssetCard = ASSET_CARD.instantiate()
	card.connect("pressed", Callable(self, "_card_pressed"))
	card.connect("delete_card", Callable(self, "_delete_card"))
	card.connect("export_assets", Callable(self, "_export_assets"))
	card.connect("open_containing_folder", Callable(self, "_card_pressed").bind(true))
	card.connect("move_to_directory_pressed", Callable(self, "_move_to_directory_pressed"))
	card.connect("show_links", Callable(self, "_show_links"))
	return card

# Shows the name dialog for a new directory.
func _on_CreateDir_pressed() -> void:
	_InputBox.popup_centered()

# Creates a new directory.
func _on_InputBox_name_entered(p_name : String) -> void:
	if name.is_empty():
		return
		
	if AssetsLibrary.get_directory_id(AssetsLibrary.current_directory, p_name) == 0:
		var dir := AssetsLibrary.create_directory(AssetsLibrary.current_directory, p_name)
		if dir != 0:
			var tmp: AssetCard
			
			# Checks if we can resuse a card or a new one needs to be created.
			if (_Cards.get_child_count() == 0) || (_Cards.get_child_count() < ITEMS_PER_PAGE):
				tmp = _create_card()
				_Cards.add_child(tmp)
			else:
				tmp = _Cards.get_children()[_Cards.get_child_count() - 1]
			
			# A new directory will be move to the first place in the container.
			_Cards.move_child(tmp, 0)
			
			var card := AMDirectory.new()
			card.id = dir
			card.name = p_name
			tmp.dataset = card
			tmp.set_parent_folder(AssetsLibrary.current_directory)
			tmp.visible = true
		else:
			# TODO: Errorhandling
			pass
	else:
		_InfoDialog.dialog_text = tr("Dir '%s' already exists in the current directory!") % name
		_InfoDialog.popup_centered()

# Leave a subdirectory.
func _on_Back_pressed() -> void:
	var dir := AMDirectory.new()
	dir.id = AssetsLibrary.get_parent_dir_id(AssetsLibrary.current_directory)
	
	_card_pressed(dir, true)

# Deletes a directory.
func _on_DeleteDirDialog_confirmed() -> void:
	var gotoroot = false
	if _DirectoriesToDelete.size() > 1:
		for dir in _DirectoriesToDelete:
			if dir.id == AssetsLibrary.current_directory:
				gotoroot = true
				break 
		
		AssetsLibrary.bulk_delete_directories(_DirectoriesToDelete)
	elif _DirectoriesToDelete.size() == 1:
		gotoroot = _DirectoriesToDelete[0].id == AssetsLibrary.current_directory
		AssetsLibrary.delete_directory(_DirectoriesToDelete[0].id)
	
	# Go back into the root directory.
	if gotoroot:
		_card_pressed(0, true)
	else:
		_card_pressed(AssetsLibrary.current_directory, true)

# Updates the content of the page, if the user starts typing in the search bar.
func _on_Search_text_changed(new_text: String) -> void:
	BrowserManager.update_search({"search_term": new_text})

func _on_Home_pressed() -> void:
	_card_pressed(0, true)

func _on_OpenLibrary_pressed() -> void:
	OS.shell_open("file://" + AssetsLibrary.get_assets_path())

func _on_CloseLib_pressed() -> void:
	ProgramManager.settings.last_opened = ""
	AssetsLibrary.close()
	get_tree().change_scene_to_file("res://Startscreen/StartScreen.tscn")

func _on_GodotTour_tour_finished():
	ProgramManager.settings.tutorial_step = ProgramManager.settings.TutorialStep.BROWSER_SCREEN

func _on_AssetLinksDialog_popup_hide():
	_card_pressed(AssetsLibrary.current_directory, true)

func _on_OverwriteDialog_popup_hide():
	_card_pressed(AssetsLibrary.current_directory, true)

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton) && (event.button_index == MOUSE_BUTTON_LEFT) && event.pressed:
		var deselectAll = true
		
		# Checks if any card if hit by the mouse click
		for card in _Cards.get_children():
			if card is AssetCard:
				if card.visible:
					if Rect2(card.global_position, card.size).has_point(event.global_position):
						deselectAll = false
						break
		if deselectAll:
			BrowserManager.deselect_all()

func _on_tag_manager_pressed() -> void:
	_SidePanel.show_view("TAG_MANAGER")

func _on_side_panel_closed() -> void:
	BrowserManager.tagging_mode = false

func _on_advanced_filter_pressed() -> void:
	_SidePanel.show_view("ADVANCED_SEARCH")
