extends Window

@onready var _Name := $MarginContainer/VBoxContainer/Name
@onready var _Description := $MarginContainer/VBoxContainer/Description
@onready var _Save := $MarginContainer/VBoxContainer/HBoxContainer/Save

var tag : AMTag = null : set = _set_tag

func _set_tag(p_tag : AMTag) -> void:
	tag = p_tag
	
	if tag:
		_Name.text = tag.name
		_Description.text = tag.description
	else:
		_Name.text = ""
		_Description.text = ""

	_Save.disabled = tag == null || tag.name.is_empty()

func _on_save_pressed() -> void:
	if tag:
		tag.name = _Name.text
		tag.description = _Description.text
		
		if tag.id != 0:
			AssetsLibrary.update_tag(tag)
		else:
			tag = AssetsLibrary.add_tag(tag)

	hide()

func _on_name_text_changed(new_text: String) -> void:
	_Save.disabled = new_text.is_empty()

func _on_size_changed() -> void:
	position = get_tree().get_root().get_viewport().size * 0.5 - size * 0.5
