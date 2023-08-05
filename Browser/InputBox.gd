extends WindowDialog

signal name_entered(name)

onready var _Text := $CenterContainer/VBoxContainer/LineEdit

func _ready() -> void:
	get_viewport().connect("size_changed", self, "_size_changed")
	
func _size_changed() -> void:
	rect_position = get_viewport_rect().size * 0.5 - rect_size * 0.5

func _on_Cancel_pressed() -> void:
	hide()

func _on_Ok_pressed() -> void:
	emit_signal("name_entered", _Text.text)
	_Text.text = ""
	hide()
