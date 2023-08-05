extends VBoxContainer

const CARD = preload("res://Browser/Card.tscn")
const FOLDER_ICON = preload("res://Assets/Material Icons/folder.svg")
const ITEMS_PER_PAGE : int = 100

onready var _Cards := $ScrollContainer/CenterContainer/Cards
onready var _ImporterDialog := $CanvasLayer/ImporterDialog
onready var _Pagination := $MarginContainer2/Pagination
onready var _Search := $MarginContainer/HBoxContainer/Search
onready var _InputBox := $CanvasLayer/InputBox
onready var _ScrollContainer := $ScrollContainer
onready var _BackButton := $MarginContainer/HBoxContainer/Back
onready var _DeleteDirDialog := $CanvasLayer/DeleteDirDialog
onready var _NativeDialog := $NativeDialog

var _CurrentDir : int = 0

var _DirectoryToDelete : int = -1

func _ready() -> void:
	if AssetsLibrary.open("c:/AssetsTest"):
		AssetsLibrary.connect("update_total_import_assets", self, "_update_total_import_assets")
		AssetsLibrary.connect("new_asset_added", self, "_new_asset_added")
		
		_Pagination.total_pages = ceil(AssetsLibrary.get_assets_count(_CurrentDir, "") / float(ITEMS_PER_PAGE))

func _update_total_import_assets(total_files : int) -> void:
	_ImporterDialog.set_total_files(total_files)
	if _ImporterDialog.visible:
		_ImporterDialog.set_value(0)
		_ImporterDialog.visible = true

func _card_pressed(id: int, is_dir : bool) -> void:
	if is_dir:
		_CurrentDir = id
		_Pagination.set_total_pages_without_update(ceil(AssetsLibrary.get_assets_count(_CurrentDir, "") / float(ITEMS_PER_PAGE)))
		_Pagination.current_page = 1
		_BackButton.mouse_default_cursor_shape = Control.CURSOR_ARROW if (_CurrentDir == 0) else Control.CURSOR_POINTING_HAND
		_BackButton.disabled = _CurrentDir == 0

func _export_assets(id: int, is_dir : bool) -> void:
	var asset : Dictionary = AssetsDatabase.get_asset(id)
	if asset.has("filename"):
		_NativeDialog.initial_path = asset["filename"]
		var file : PoolStringArray = _NativeDialog.show_modal()
		if !file.empty():
			if !is_dir:
				AssetsLibrary.export_asset(id, file[0])
	
func _delete_card(id: int, is_dir : bool) -> void:
	if is_dir:
		_DirectoryToDelete = id
		_DeleteDirDialog.popup_centered()
		
func _asset_dropped(id : int, dopped_id : int, dropped_is_dir : bool) -> void:
	var moved_succefully : bool = false
	if dropped_is_dir:
		moved_succefully = AssetsLibrary.move_directory(id, dopped_id)
	else:
		moved_succefully = AssetsLibrary.move_asset(id, dopped_id)
	
	if moved_succefully:
		_card_pressed(_CurrentDir, true)
		
func _new_asset_added(name : String, thumbnail : Texture) -> void:
	if _Cards.get_child_count() < ITEMS_PER_PAGE:
		var tmp := CARD.instance()
		tmp.connect("pressed", self, "_card_pressed")
		_Cards.add_child(tmp)
		tmp.set_texture(thumbnail)
		tmp.set_title(name)
		_ImporterDialog.increment_value()
	
	if _ImporterDialog.get_value() == _ImporterDialog.get_total_files():
		_ImporterDialog.hide()

func _on_Pagination_page_update(page : int) -> void:
	if _Cards:
		_ScrollContainer.scroll_vertical = 0
		_ScrollContainer.scroll_horizontal = 0
		var cards := AssetsLibrary.query_assets(_CurrentDir, _Search.text, (page - 1) * ITEMS_PER_PAGE, ITEMS_PER_PAGE)
		for child in _Cards.get_children():
			child.hide()
		
		var count = 0
		for card in cards:
			var tmp
			
			# Creates or reuses a card element.
			if count >= _Cards.get_child_count():
				tmp = CARD.instance()
				tmp.connect("pressed", self, "_card_pressed")
				tmp.connect("delete_card", self, "_delete_card")
				tmp.connect("asset_dropped", self, "_asset_dropped")
				tmp.connect("export_assets", self, "_export_assets")
				_Cards.add_child(tmp)
			else:
				tmp = _Cards.get_child(count)
				tmp.visible = true
				
			count += 1
			
			tmp.id = card["id"]
			if card.has("thumbnail"):
				tmp.set_texture(card["thumbnail"])
				tmp.is_dir = false
			else:
				tmp.set_texture(FOLDER_ICON)
				tmp.is_dir = true
				
			tmp.set_title(card["name"])

func _on_Search_text_entered(_new_text: String) -> void:
	pass
	#_Pagination.set_total_pages_without_update(ceil(AssetsLibrary.get_assets_count(_CurrentDir, _Search.text) / float(ITEMS_PER_PAGE)))
	#_Pagination.current_page = 1

func _on_CreateDir_pressed() -> void:
	_InputBox.popup_centered()

func _on_InputBox_name_entered(name : String) -> void:
	if name.empty():
		return
	
	var dir := AssetsLibrary.create_directory(_CurrentDir, name)
	if dir != 0:
		var tmp
		if (_Cards.get_child_count() == 0) || (_Cards.get_child_count() < ITEMS_PER_PAGE):
			tmp = CARD.instance()
			tmp.connect("pressed", self, "_card_pressed")
			tmp.connect("delete_card", self, "_delete_card")
			tmp.connect("asset_dropped", self, "_asset_dropped")
			tmp.connect("export_assets", self, "_export_assets")
			_Cards.add_child(tmp)
		else:
			tmp = _Cards.get_children()[_Cards.get_child_count() - 1]
		
		_Cards.move_child(tmp, 0)
		tmp.set_texture(FOLDER_ICON)
		tmp.set_title(name)
		tmp.id = dir
		tmp.is_dir = true
		tmp.visible = true
	else:
		# TODO: Errorhandling
		pass

func _on_Back_pressed() -> void:
	_card_pressed(AssetsLibrary.get_parent_dir_id(_CurrentDir), true)

func _on_DeleteDirDialog_confirmed() -> void:
	if AssetsLibrary.delete_directory(_DirectoryToDelete):
		# Go back into the root directory.
		if _CurrentDir == _DirectoryToDelete:
			_card_pressed(0, true)
		else:
			_card_pressed(_CurrentDir, true)
	else:
		# Todo: Errorhandling
		pass

func _on_Search_text_changed(new_text: String) -> void:
	#if (_Search.text.length() >= 3) || _Search.text.empty():
	_Pagination.set_total_pages_without_update(ceil(AssetsLibrary.get_assets_count(_CurrentDir, _Search.text) / float(ITEMS_PER_PAGE)))
	_Pagination.current_page = 1
