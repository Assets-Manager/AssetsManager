extends WindowDialog

func _ready() -> void:
	get_close_button().hide()
	get_viewport().connect("size_changed", self, "_size_changed")
	
func _size_changed() -> void:
	rect_position = get_viewport_rect().size * 0.5 - rect_size * 0.5

func _on_Accept_pressed() -> void:
	ProgramManager.settings.disclaimer_accepted = true
	hide()

func _on_Deny_pressed() -> void:
	get_tree().quit()
