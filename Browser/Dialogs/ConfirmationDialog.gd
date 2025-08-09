extends ConfirmationDialog

func _ready() -> void:
	get_tree().get_root().get_viewport().size_changed.connect(_size_changed)
	get_ok_button().text = tr("Yes")
	get_cancel_button().text = tr("No")
	
func _size_changed() -> void:
	position = get_tree().get_root().get_viewport().size * 0.5 - size * 0.5
