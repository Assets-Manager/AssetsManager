extends Window

signal name_entered(name)

@onready var _Text := $CenterContainer/MarginContainer/VBoxContainer/LineEdit

func _ready() -> void:
	unresizable = true
	get_tree().get_root().get_viewport().size_changed.connect(_size_changed)
	
func _size_changed() -> void:
	position = get_tree().get_root().get_viewport().size * 0.5 - size * 0.5

func _on_Cancel_pressed() -> void:
	hide()

func _on_Ok_pressed() -> void:
	emit_signal("name_entered", _Text.text)
	_Text.text = ""
	hide()

func _on_visibility_changed() -> void:
	if visible:
		_Text.grab_focus()

func _on_line_edit_text_submitted(new_text: String) -> void:
	_on_Ok_pressed()
