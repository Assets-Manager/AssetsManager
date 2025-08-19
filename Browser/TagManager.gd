class_name TagManager extends MarginContainer

signal changed

@onready var _EditTagDialog := $CanvasLayer/EditTagDialog
@onready var _Tags := $VBoxContainer/ItemList
@onready var _Delete := $VBoxContainer/HBoxContainer/Delete
@onready var _Confirm := $CanvasLayer/ConfirmationDialog
@onready var _SaveTags := $VBoxContainer/SaveTags
@onready var _ToggleDelete := $VBoxContainer/ToggleDelete
@onready var _RecursiveTagAction := $CanvasLayer/ConfirmationDialog2

@onready var _AddTag := $VBoxContainer/HBoxContainer/AddTag

var _SelectedTags : Array[AMTag] = []
var _SelectedAssets : Array = []

@export var toggle_mode : bool = false : set = _set_toggle_mode

func _ready() -> void:
	BrowserManager.card_selection_changed.connect(_card_selection_changed)
	_set_toggle_mode(toggle_mode)
	_update_tags()

func _set_toggle_mode(value: bool) -> void:
	toggle_mode = value
	
	if _Tags:
		if toggle_mode:
			_Tags.select_mode = ItemList.SELECT_TOGGLE
			add_theme_constant_override("margin_bottom", 0)
			add_theme_constant_override("margin_top", 0)
			add_theme_constant_override("margin_left", 0)
			add_theme_constant_override("margin_right", 0)
			_ToggleDelete.visible = false
			_SaveTags.visible = false
			_AddTag.visible = false
			_Delete.visible = false
		else:
			_Tags.select_mode = ItemList.SELECT_MULTI
			add_theme_constant_override("margin_bottom", 16)
			add_theme_constant_override("margin_top", 16)
			add_theme_constant_override("margin_left", 16)
			add_theme_constant_override("margin_right", 16)
			_ToggleDelete.visible = true
			_SaveTags.visible = true
			_AddTag.visible = true
			_Delete.visible = true

func _exit_tree() -> void:
	BrowserManager.card_selection_changed.disconnect(_card_selection_changed)

func _card_selection_changed() -> void:
	var selected = BrowserManager.get_selected_assets(null)
	_SaveTags.disabled = selected.is_empty()

func get_selected_tags() -> Array[AMTag]:
	return _SelectedTags

func set_selected_tags(tags: Array[AMTag]) -> void:
	_SelectedTags = tags
	_Tags.deselect_all()
	for idx in _Tags.item_count:
		var id = _Tags.get_item_metadata(idx).id
		for t in tags:
			if t.id == id:
				_Tags.select(idx)
				break

func _update_tags() -> void:
	_Tags.clear()
	var tags : Array[AMTag] = AssetsLibrary.get_all_tags()
	for tag in tags:
		_Tags.add_item(tag.name)
		_Tags.set_item_tooltip(_Tags.item_count - 1, tag.description)
		_Tags.set_item_metadata(_Tags.item_count - 1, tag)

func _on_add_tag_pressed() -> void:
	_EditTagDialog.tag = AMTag.new()
	_EditTagDialog.popup_centered()

func _on_edit_tag_dialog_visibility_changed() -> void:
	if !_EditTagDialog.visible:
		_update_tags()

func _on_item_list_item_activated(index: int) -> void:
	_EditTagDialog.tag = _Tags.get_item_metadata(index)
	_EditTagDialog.popup_centered()

func _on_item_list_multi_selected(_index: int, _selected: bool) -> void:
	_Delete.disabled = _Tags.get_selected_items().size() == 0
	emit_signal("changed")
	
	_SelectedTags.clear()
	for idx in _Tags.get_selected_items():
		_SelectedTags.push_back(_Tags.get_item_metadata(idx))
	
	if !toggle_mode:
		BrowserManager.tagging_mode = true
	
func _on_delete_pressed() -> void:
	_Confirm.popup_centered()

func _on_confirmation_dialog_confirmed() -> void:
	for idx in _Tags.get_selected_items():
		AssetsLibrary.delete_tag(_Tags.get_item_metadata(idx))
	BrowserManager.tagging_mode = false
	_Delete.disabled = true
	_update_tags()

func _on_item_list_empty_clicked(_at_position: Vector2, _mouse_button_index: int) -> void:
	_Tags.deselect_all()
	_SelectedTags.clear()
	_SaveTags.disabled = true
	
	if !toggle_mode:
		BrowserManager.tagging_mode = false

func _on_save_tags_pressed() -> void:
	_SelectedAssets = BrowserManager.get_selected_assets(null)
	var showDialog = false
	for asset in _SelectedAssets:
		if asset is AMDirectory:
			showDialog = true
			break
			
	if showDialog:
		_RecursiveTagAction.popup_centered()
	else:
		_update_asset_tags(false)

func _update_asset_tags(recursive: bool) -> void:
	if _ToggleDelete.button_pressed:
		AssetsLibrary.remove_tags(_SelectedAssets, _SelectedTags, recursive)
	else:
		AssetsLibrary.add_tags(_SelectedAssets, _SelectedTags, recursive)
		
	_on_item_list_empty_clicked(Vector2.ZERO, 0)
	_SelectedAssets = []

func _on_confirmation_dialog_2_confirmed() -> void:
	_update_asset_tags(true)

func _on_confirmation_dialog_2_canceled() -> void:
	_update_asset_tags(false)
