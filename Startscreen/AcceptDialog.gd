extends AcceptDialog

func _ready() -> void:
	get_tree().get_root().get_viewport().size_changed.connect(_size_changed)
	
func _size_changed() -> void:
	position = get_tree().get_root().get_viewport().size * 0.5 - size * 0.5
