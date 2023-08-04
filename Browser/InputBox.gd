extends WindowDialog

signal name_entered(name)

onready var _Text := $CenterContainer/VBoxContainer/LineEdit

func _on_Cancel_pressed() -> void:
	hide()

func _on_Ok_pressed() -> void:
	emit_signal("name_entered", _Text.text)
	_Text.text = ""
	hide()
