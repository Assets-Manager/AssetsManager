class_name AssetCard extends MarginContainer

const FOLDER_ICON = preload("res://Assets/Material Icons/folder.svg")
const HIGHLIGHT_STYLEBOX = preload("res://Assets/Styleboxes/Button/button_highlight.stylebox")

signal pressed(data, is_dir: bool)

## Called if one or more cards should be delete
## [br]
## - [param dirs], this could be either the dataset of this card or an array of datasets for bulk deletetion
signal delete_card(dirs: Array[AMDirectory])

## Allows to export all selected datasets
signal export_assets(datasets: Array)

## Called if a card should be moved via the move dialog
## [br]
## - [param datasets], array of datasets for bulk movement
signal move_to_directory_pressed(datasets: Array)
signal open_containing_folder(parent_folder: int)
signal show_links(id: int)

@onready var _Card : Panel = $Card
@onready var _Texture := $Card/MarginContainer/VBoxContainer/TextureRect
@onready var _Title := $Card/MarginContainer/VBoxContainer/Title
@onready var _Animation := $AnimationPlayer
@onready var _Move := $Card/HBoxContainer/Move
@onready var _Delete := $Card/HBoxContainer/Delete
@onready var _OpenFolder := $Card/HBoxContainer/OpenFolder
@onready var _ShowLinks := $Card/HBoxContainer2/ShowLinks
@onready var _RemoveLink := $Card/HBoxContainer2/RemoveLink
@onready var _Export := $Card/HBoxContainer/Export
@onready var _EditField := $Card/EditField
@onready var _Info := $Card/HBoxContainer/Info

static var _CurrentVisibleEditField : LineEdit = null

var is_dir : bool = false : get = _get_is_dir
var dataset = null : set = _set_dataset
var _ParentFolder : int = 0

func _ready() -> void:
	_OpenFolder.hide()
	BrowserManager.enter_tagging_mode.connect(_enter_tagging_mode)
	BrowserManager.leave_tagging_mode.connect(_leave_tagging_mode)
	
func _enter_tagging_mode() -> void:
	_RemoveLink.visible = false
	_ShowLinks.visible = false
	_Delete.visible = false
	_Export.visible = false
	_Move.visible = false
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
func _leave_tagging_mode() -> void:
	_Export.visible = true
	_Move.visible = true
	BrowserManager.deselect_all()
	_update_controls()
	
func set_parent_folder(parent_folder : int) -> void:
	_ParentFolder = parent_folder
	_OpenFolder.visible = _ParentFolder != AssetsLibrary.current_directory

func _get_is_dir() -> bool:
	return (dataset != null) && (dataset is AMDirectory)

func _set_dataset(p_dataset) -> void:
	dataset = p_dataset
	_update_controls()
	if dataset is AMDirectory:
		_Texture.texture = FOLDER_ICON
		_Info.visible = true
		_set_title(dataset.name)
	elif dataset is AMAsset:
		_Texture.texture = dataset.thumbnail
		_Info.visible = false
		_set_title(dataset.filename)

func _update_controls() -> void:
	_Delete.visible = is_dir
	mouse_default_cursor_shape = Control.CURSOR_MOVE if !is_dir else Control.CURSOR_POINTING_HAND

	_ShowLinks.visible = (AssetsLibrary.get_asset_linked_dirs(dataset.id).size() > 1) && !is_dir
	_RemoveLink.visible = (AssetsLibrary.current_directory != 0) && !is_dir

func _set_title(title : String) -> void:
	_Title.text = title
	tooltip_text = title

func _on_Card_mouse_entered() -> void:
	if is_dir && (scale == Vector2.ONE) && !BrowserManager.tagging_mode:
		_Animation.play("Hover")

func _on_Card_mouse_exited() -> void:
	if !Rect2(Vector2(), size).has_point(get_local_mouse_position()):
		if is_dir && !BrowserManager.tagging_mode:
			_Animation.play_backwards("Hover")
		else:
			_Animation.play("RESET")

func _process(_delta: float) -> void:
	if scale != Vector2.ONE:
		_on_Card_mouse_exited()
		
func _change_selection_state(selected: bool) -> void:
	if selected:
		_Card.add_theme_stylebox_override("panel", HIGHLIGHT_STYLEBOX)
	else:
		_Card.remove_theme_stylebox_override("panel")

func _on_Card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT) && !event.pressed:
			if event.ctrl_pressed || BrowserManager.tagging_mode:
				if BrowserManager.tagging_mode && is_in_group("selected_assets_cards"):
					remove_from_group("selected_assets_cards")
					_change_selection_state(false)
				else:
					add_to_group("selected_assets_cards")
					_change_selection_state(true)
					
				BrowserManager.emit_card_selection_changed()
			else:
				BrowserManager.deselect_all()
				emit_signal("pressed", dataset, is_dir)

func _on_Delete_pressed() -> void:
	var datasets : Array[AMDirectory] = BrowserManager.get_selected_directories(dataset)
	if !datasets.is_empty():
		emit_signal("delete_card", datasets)

func _can_drop_data(_position: Vector2, data) -> bool:
	return is_dir && ((!(data is Array) && data != self) || data is Array)

func _drop_data(_position: Vector2, data) -> void:
	if data is Array:
		AssetsLibrary.bulk_move(data, dataset.id)
	else:
		AssetsLibrary.move(data, dataset.id)
	BrowserManager.refresh_ui()

func _get_drag_data(_position: Vector2):
	var nodes := get_tree().get_nodes_in_group("selected_assets_cards")
	if !nodes.is_empty():
		var hflow := HFlowContainer.new()
		hflow.modulate.a = 0.5
		hflow.custom_minimum_size.x = 200 * 4
		hflow.add_theme_constant_override("h_separation", -100)
		hflow.add_theme_constant_override("v_separation", -100)
		
		var zindex = nodes.size()
		var datasets : Array = []
		for node in nodes:
			var tmp : AssetCard = node.duplicate()
			tmp.z_index = zindex
			zindex -= 1
			hflow.add_child(tmp)
			datasets.push_back(node.dataset)
		set_drag_preview(hflow)
		return datasets
	
	var card : Control = self.duplicate()
	card.modulate.a = 0.5
	set_drag_preview(card)
	return self.dataset

func _on_Export_pressed() -> void:
	var datasets : Array = BrowserManager.get_selected_datasets(dataset)
	if !datasets.is_empty():
		emit_signal("export_assets", datasets)

func _on_OpenFolder_pressed() -> void:
	emit_signal("open_containing_folder", _ParentFolder)

func _on_Move_pressed() -> void:
	emit_signal("move_to_directory_pressed", BrowserManager.get_selected_datasets(dataset))

func _on_RemoveLink_pressed():
	AssetsLibrary.bulk_unlink_assets(BrowserManager.get_selected_datasets(dataset), AssetsLibrary.current_directory)
	BrowserManager.refresh_ui()

func _on_ShowLinks_pressed():
	emit_signal("show_links", dataset.id)

func _on_title_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT) && event.pressed && !BrowserManager.tagging_mode:
			_EditField.position = make_canvas_position_local(_Title.global_position) - Vector2(8, 8)
			_EditField.size = _Title.size
			_EditField.text = _Title.text
			
			# Hide any other field
			if _CurrentVisibleEditField:
				_CurrentVisibleEditField.hide()
			
			_EditField.show()
			_EditField.grab_focus()
			_EditField.caret_column = _EditField.text.length()
			_CurrentVisibleEditField = _EditField

func _on_edit_field_text_submitted(new_text: String) -> void:
	if AssetsLibrary.rename(dataset.id, new_text, is_dir):
		_set_title(new_text)
	_EditField.hide()
	_CurrentVisibleEditField = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("ui_cancel") || ((event is InputEventMouseButton) && (event.button_index == MOUSE_BUTTON_LEFT) && event.pressed):
		_EditField.hide()
		_CurrentVisibleEditField = null

func _on_edit_field_text_changed(new_text: String) -> void:
	new_text.is_valid_filename()

func _on_edit_field_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# No illegal file names
		if event.unicode != 0 && event.unicode != 32 && !String.chr(event.unicode).is_valid_filename():
			accept_event()

func _on_info_pressed() -> void:
	BrowserManager.show_file_info(dataset)
