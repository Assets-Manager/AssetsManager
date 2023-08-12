extends ConfirmationDialog

func _ready() -> void:
	get_viewport().connect("size_changed", self, "_size_changed")
	get_ok().text = tr("Yes")
	get_cancel().text = tr("No")
	
func _size_changed() -> void:
	rect_position = get_viewport_rect().size * 0.5 - rect_size * 0.5
