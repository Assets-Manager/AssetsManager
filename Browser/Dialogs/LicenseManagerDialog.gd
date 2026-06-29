extends Window

@onready var _Licenses := $MarginContainer/HBoxContainer/VBoxContainer/Licenses
@onready var _LicenseName := $MarginContainer/HBoxContainer/VBoxContainer/Licenses/LicenseName
@onready var _EditButtons := $MarginContainer/HBoxContainer/VBoxContainer2/EditButtons
@onready var _LicenseText := $MarginContainer/HBoxContainer/VBoxContainer2/LicenseText
@onready var _SaveButton := $MarginContainer/HBoxContainer/VBoxContainer2/Save
@onready var _RemoveLicense := $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/RemoveLicense

func _ready() -> void:
	var licenses = AssetsLibrary.get_all_licenses()
	_Licenses.clear()
	
	for license in licenses:
		_Licenses.add_item(license.name)
		_Licenses.set_item_metadata(_Licenses.item_count - 1, license)

func _on_add_license_pressed() -> void:
	_Licenses.add_item("")
	await get_tree().process_frame
	
	_show_edit_box(_Licenses.item_count - 1)
	
func _show_edit_box(idx: int) -> void:
	var rect : Rect2 = _Licenses.get_item_rect(idx)
	_LicenseName.set_meta("current_idx", idx)
	_LicenseName.text = _Licenses.get_item_text(idx)
	_LicenseName.position = rect.position
	_LicenseName.size = rect.size
	_LicenseName.visible = true
	_LicenseName.grab_focus()
	await get_tree().process_frame
	_LicenseName.caret_column = _LicenseName.text.length()

func _on_license_name_text_submitted(_new_text: String) -> void:
	_set_license_name()

func _on_license_name_focus_exited() -> void:
	_set_license_name()

func _set_license_name() -> void:
	if _LicenseName.visible:
		_LicenseName.visible = false
		var idx = _LicenseName.get_meta("current_idx")
		if idx != null:
			var license: AMLicense = _Licenses.get_item_metadata(idx)
			if _LicenseName.text == "" && !license:
				_Licenses.remove_item(idx)
			else:
				if _LicenseName.text != "":
					if license:
						license.name = _LicenseName.text
						AssetsLibrary.update_license(license)
					else:
						license = AMLicense.new()
						license.name = _LicenseName.text
						_Licenses.set_item_metadata(idx, AssetsLibrary.add_license(license))
					
					_Licenses.set_item_text(idx, _LicenseName.text)
					_LicenseName.text = ""

func _on_licenses_item_activated(index: int) -> void:
	_show_edit_box(index)

func _on_licenses_item_selected(idx: int) -> void:
	_SaveButton.disabled = false
	_LicenseText.editable = true
	_RemoveLicense.disabled = false
	
	var license: AMLicense = _Licenses.get_item_metadata(idx)
	_LicenseText.text = license.text

func _on_edit_button_pressed(mustache: String) -> void:
	_LicenseText.insert_text_at_caret(mustache)

func _on_license_text_focus_entered() -> void:
	if _LicenseText.editable:
		_set_edit_button_state(false)
	
func _set_edit_button_state(disabled: bool) -> void:
	for c in _EditButtons.get_children():
		if c is Button:
			c.disabled = disabled

func _on_license_text_focus_exited() -> void:
	_set_edit_button_state(true)

func _on_remove_license_pressed() -> void:
	$CanvasLayer/ConfirmationDialog.popup_centered()

func _on_save_pressed() -> void:
	var selected : PackedInt32Array = _Licenses.get_selected_items()
	if !selected.is_empty():
		var license: AMLicense = _Licenses.get_item_metadata(selected[0])
		license.text = _LicenseText.text
		AssetsLibrary.update_license(license)

func _on_close_pressed() -> void:
	_reset()
	hide()

func _reset() -> void:
	_Licenses.deselect_all()
	_set_edit_button_state(true)
	_SaveButton.disabled = true
	_LicenseText.editable = false
	_LicenseText.text = ""
	_RemoveLicense.disabled = false

func _on_confirmation_dialog_confirmed() -> void:
	var selected : PackedInt32Array = _Licenses.get_selected_items()
	if !selected.is_empty():
		var license: AMLicense = _Licenses.get_item_metadata(selected[0])
		AssetsLibrary.delete_license(license)
		_Licenses.remove_item(selected[0])
	_reset()
