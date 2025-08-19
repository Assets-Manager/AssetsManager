extends Window

signal disclaimer_accepted()

func _ready() -> void:
#	get_close_button().hide()
	get_viewport().connect("size_changed", Callable(self, "_size_changed"))

func _on_Accept_pressed() -> void:
	ProgramManager.settings.disclaimer_accepted = true
	disclaimer_accepted.emit()
	hide()

func _on_Deny_pressed() -> void:
	get_tree().quit()

func _on_close_requested() -> void:
	get_tree().quit()
