extends VBoxContainer

const CARD = preload("res://Browser/Card.tscn")
const FOLDER_ICON = preload("res://Assets/Material Icons/folder.svg")
const ITEMS_PER_PAGE : int = 100

onready var _Cards := $ScrollContainer/CenterContainer/Cards
onready var _ImporterDialog := $CanvasLayer/ImporterDialog
onready var _DirectoryMoveDialog := $CanvasLayer/DirectoryMoveDialog
onready var _Pagination := $MarginContainer2/HBoxContainer/Pagination
onready var _Search := $MarginContainer/HBoxContainer/Search
onready var _InputBox := $CanvasLayer/InputBox
onready var _ScrollContainer := $ScrollContainer
onready var _BackButton := $MarginContainer/HBoxContainer/Back
onready var _HomeButton := $MarginContainer/HBoxContainer/Home
onready var _DeleteDirDialog := $CanvasLayer/DeleteDirDialog
onready var _NativeDialog := $NativeDialog
onready var _InfoDialog := $CanvasLayer/InfoDialog
onready var _GodotTour := $CanvasLayer/GodotTour
onready var _OverwriteDialog := $CanvasLayer/OverwriteDialog
onready var _AssetLinksDialog := $CanvasLayer/AssetLinksDialog

var _DirectoryToDelete : int = -1
var _VisibleCards : int = 0
var _FilesToApprove : Array = []

var _Thumbnail : Texture = null
var _ThumbnailThread : Thread = null

func _ready() -> void:
	# Connects all events of the library.
	AssetsLibrary.connect("update_total_import_assets", self, "_update_total_import_assets")
	AssetsLibrary.connect("files_to_check", self, "_files_to_check")
	
	# IMPORTANT: These MUST be called deferred, since this signals are emitted inside a thread.
	AssetsLibrary.connect("new_asset_added", self, "_new_asset_added", [], CONNECT_DEFERRED)
	AssetsLibrary.connect("increase_import_counter", self, "_increase_import_counter", [], CONNECT_DEFERRED)
	
	# Updates the initial pagination
	_Pagination.total_pages = ceil(AssetsLibrary.get_assets_count(AssetsLibrary.current_directory, "") / float(ITEMS_PER_PAGE))
	
	# Does the user already did the tutorial?
	if ProgramManager.settings.tutorial_step < ProgramManager.settings.TutorialStep.BROWSER_SCREEN:
		_GodotTour.visible = true
		_GodotTour.start()
	else:
		_GodotTour.visible = false

# ---------------------------------------------
# 			   UI import update
# ---------------------------------------------

func _process(delta):
	# Is a render thread running?
	# If so than wait for it to finish.
	if _ThumbnailThread && !_ThumbnailThread.is_alive():
		_Thumbnail = _ThumbnailThread.wait_to_finish()
		_ThumbnailThread = null
	elif !_ThumbnailThread && !_ImporterDialog.visible && !_FilesToApprove.empty() && \
		 !_OverwriteDialog.visible:
		var file : Dictionary = _FilesToApprove.back()
		match file.status:
			AssetsLibrary.FileImportStatus.STATUS_OVERWRITE:
				# Starts a new render thread, if there is currently no thumnail available.
				if !_Thumbnail:
					_ThumbnailThread = Thread.new()
					_ThumbnailThread.start(self, "_render_thumbnail", file)
				else:
					# Sets the newly dropped asset for the dialog
					_FilesToApprove.pop_back() # This is faster than pop_front
					_OverwriteDialog.set_new_asset(_Thumbnail, file)
					_OverwriteDialog.popup_centered()
					_Thumbnail = null

# Renders the thumnail. Since some importers only work on the main thread,
# this one must be called outside of the main thread, to avoid locking.
func _render_thumbnail(file) -> Texture:
	return file.importer.render_thumbnail(file.file)

func _exit_tree() -> void:
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
func _files_to_check(files: Array) -> void:
	_FilesToApprove.append_array(files)

# Called if a new assets were successfully imported
# Updates the progressbar of the importer dialog.
func _new_asset_added(id: int, name : String, thumbnail : Texture) -> void:
	# Only add a new card to the gui, if the max items per page isn't reached.
	if (_Cards.get_child_count() < ITEMS_PER_PAGE) || (_VisibleCards < _Cards.get_child_count()):
		var tmp = null
		
		# Checks if a card needs to be updated
		for child in _Cards.get_children():
			if !child.visible:
				break
				
			if child.id == id:
				tmp = child
				break
		
		if !tmp:
			if _Cards.get_child_count() < ITEMS_PER_PAGE:
				tmp = _create_card()
				_Cards.add_child(tmp)
			elif _VisibleCards < _Cards.get_child_count():
				tmp = _Cards.get_child(_VisibleCards)
			
		tmp.set_texture(thumbnail)
		tmp.set_title(name)
		tmp.set_parent_folder(0)
		tmp.id = id
		tmp.is_dir = false
		tmp.visible = true
		_VisibleCards += 1
	else:
		_Pagination.total_pages = ceil(AssetsLibrary.get_assets_count(AssetsLibrary.current_directory, "") / float(ITEMS_PER_PAGE))
	
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
		
		var cards := AssetsLibrary.query_assets(AssetsLibrary.current_directory, _Search.text, (page - 1) * ITEMS_PER_PAGE, ITEMS_PER_PAGE)
		
		# Hide all card, which are currently visible, since we reuse them later.
		for child in _Cards.get_children():
			child.hide()
		
		# Reuse counter.
		_VisibleCards = 0
		for card in cards:
			var tmp
			
			# Creates or reuses a card element.
			if _VisibleCards >= _Cards.get_child_count():
				tmp = _create_card()
				_Cards.add_child(tmp)
			else:
				tmp = _Cards.get_child(_VisibleCards)
				tmp.visible = true
			
			_VisibleCards += 1
			
			# Sets the parent folder id, if the user searches in the root url.
			# So the user can open the containing folder of an asset.
			if !_Search.text.empty() && (AssetsLibrary.current_directory == 0) && card.has("parent_id") && (card["parent_id"] != null):
				tmp.set_parent_folder(card["parent_id"])
			else:
				tmp.set_parent_folder(0)
			
			# Fill the needed informations for a card.
			tmp.id = card["id"]
			if card.has("thumbnail"):
				tmp.set_texture(card["thumbnail"])
				tmp.is_dir = false
			else:
				tmp.set_texture(FOLDER_ICON)
				tmp.is_dir = true
				
			tmp.set_title(card["name"])

# ---------------------------------------------
# 			    Card signals
# ---------------------------------------------

func _move_to_directory_pressed(id: int, is_dir : bool) -> void:
	_DirectoryMoveDialog.show_dialog(id, is_dir)
	
func _show_links(id: int) -> void:
	_AssetLinksDialog.set_asset_id(id)
	_AssetLinksDialog.popup_centered()
	
func _remove_link(id: int) -> void:
	if AssetsLibrary.unlink_asset(AssetsLibrary.current_directory, id):
		_card_pressed(AssetsLibrary.current_directory, true)
	
func _card_pressed(id: int, is_dir : bool) -> void:
	# Opens the pressed directory.
	if is_dir:
		AssetsLibrary.current_directory = id
		_Pagination.set_total_pages_without_update(ceil(AssetsLibrary.get_assets_count(AssetsLibrary.current_directory, _Search.text) / float(ITEMS_PER_PAGE)))
		_Pagination.current_page = 1
		_BackButton.mouse_default_cursor_shape = Control.CURSOR_ARROW if (AssetsLibrary.current_directory == 0) else Control.CURSOR_POINTING_HAND
		_HomeButton.mouse_default_cursor_shape = _BackButton.mouse_default_cursor_shape
		_BackButton.disabled = AssetsLibrary.current_directory == 0
		_HomeButton.disabled = _BackButton.disabled

# Exports an asset
func _export_assets(id: int, is_dir : bool) -> void:
	if !is_dir:	# Export one asset file
		_NativeDialog.dialog_type = 1
		var asset : Dictionary = AssetsLibrary.get_asset_by_id(id)
		if asset.has("filename"):
			_NativeDialog.initial_path = asset["filename"]
			var file : PoolStringArray = _NativeDialog.show_modal()
			if !file.empty():
				AssetsLibrary.export_asset(id, file[0])
	else:	# Export a folder
		_NativeDialog.dialog_type = 2
		var folder : PoolStringArray = _NativeDialog.show_modal()
		if !folder.empty():
			AssetsLibrary.export_assets(id, folder[0])

func _delete_card(id: int, is_dir : bool) -> void:
	if is_dir:
		_DirectoryToDelete = id
		_DeleteDirDialog.popup_centered()

# Called if a directory or asset was dropped onto a directory.
func _asset_dropped(id : int, dopped_id : int, dropped_is_dir : bool) -> void:
	var moved_succefully : bool = false
	if dropped_is_dir:
		moved_succefully = AssetsLibrary.move_directory(id, dopped_id)
	else:
		# Prevents the asset to be moved into a directory, where it is already in.
		if !AssetsLibrary.is_asset_in_dir(dopped_id, id):
			moved_succefully = AssetsLibrary.move_asset(id, dopped_id)
	
	if moved_succefully:
		_card_pressed(AssetsLibrary.current_directory, true)


func _on_DirectoryMoveDialog_move_item(parent_id: int, id: int, is_dir: bool) -> void:
	_asset_dropped(parent_id, id, is_dir)

func _on_DirectoryMoveDialog_refresh_ui():
	_card_pressed(AssetsLibrary.current_directory, true)

# ---------------------------------------------
# 	   Different ui actions and functions
# ---------------------------------------------

# Creates a new card object.
func _create_card():
	var card = CARD.instance()
	card.connect("pressed", self, "_card_pressed")
	card.connect("delete_card", self, "_delete_card")
	card.connect("asset_dropped", self, "_asset_dropped")
	card.connect("export_assets", self, "_export_assets")
	card.connect("open_containing_folder", self, "_card_pressed", [true])
	card.connect("move_to_directory_pressed", self, "_move_to_directory_pressed")
	card.connect("remove_link", self, "_remove_link")
	card.connect("show_links", self, "_show_links")
	return card

# Shows the name dialog for a new directory.
func _on_CreateDir_pressed() -> void:
	_InputBox.popup_centered()

# Creates a new directory.
func _on_InputBox_name_entered(name : String) -> void:
	if name.empty():
		return
		
	if AssetsLibrary.get_directory_id(AssetsLibrary.current_directory, name) == 0:
		var dir := AssetsLibrary.create_directory(AssetsLibrary.current_directory, name)
		if dir != 0:
			var tmp
			
			# Checks if we can resuse a card or a new one needs to be created.
			if (_Cards.get_child_count() == 0) || (_Cards.get_child_count() < ITEMS_PER_PAGE):
				tmp = _create_card()
				_Cards.add_child(tmp)
			else:
				tmp = _Cards.get_children()[_Cards.get_child_count() - 1]
			
			# A new directory will be move to the first place in the container.
			_Cards.move_child(tmp, 0)
			tmp.set_texture(FOLDER_ICON)
			tmp.set_title(name)
			tmp.id = dir
			tmp.is_dir = true
			tmp.visible = true
		else:
			# TODO: Errorhandling
			pass
	else:
		_InfoDialog.dialog_text = tr("Directory '%s' already exists in the current directory!") % name
		_InfoDialog.popup_centered()

# Leave a subdirectory.
func _on_Back_pressed() -> void:
	_card_pressed(AssetsLibrary.get_parent_dir_id(AssetsLibrary.current_directory), true)

# Deletes a directory.
func _on_DeleteDirDialog_confirmed() -> void:
	if AssetsLibrary.delete_directory(_DirectoryToDelete):
		# Go back into the root directory.
		if AssetsLibrary.current_directory == _DirectoryToDelete:
			_card_pressed(0, true)
		else:
			_card_pressed(AssetsLibrary.current_directory, true)
	else:
		# Todo: Errorhandling
		pass

# Updates the content of the page, if the user starts typing in the search bar.
func _on_Search_text_changed(_new_text: String) -> void:
	_Pagination.set_total_pages_without_update(ceil(AssetsLibrary.get_assets_count(AssetsLibrary.current_directory, _Search.text) / float(ITEMS_PER_PAGE)))
	_Pagination.current_page = 1

func _on_Home_pressed() -> void:
	_card_pressed(0, true)

func _on_OpenLibrary_pressed() -> void:
	OS.shell_open("file://" + AssetsLibrary.get_assets_path())

func _on_CloseLib_pressed() -> void:
	ProgramManager.settings.last_opened = ""
	AssetsLibrary.close()
	get_tree().change_scene("res://Startscreen/StartScreen.tscn")

func _on_GodotTour_tour_finished():
	ProgramManager.settings.tutorial_step = ProgramManager.settings.TutorialStep.BROWSER_SCREEN

func _on_AssetLinksDialog_popup_hide():
	_card_pressed(AssetsLibrary.current_directory, true)

func _on_OverwriteDialog_popup_hide():
	_card_pressed(AssetsLibrary.current_directory, true)
