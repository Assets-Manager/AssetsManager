extends Window

@onready var _Progressbar := $CenterContainer/MarginContainer/VBoxContainer/ProgressBar

func _ready() -> void:
	unresizable = true
	get_tree().get_root().get_viewport().size_changed.connect(_size_changed)
	
func _size_changed() -> void:
	position = get_tree().get_root().get_viewport().size * 0.5 - size * 0.5
	
func set_total_files(value : int) -> void:
	_Progressbar.max_value = value
	
func get_total_files() -> int:
	return _Progressbar.max_value
	
func set_value(value : int) -> void:
	_Progressbar.value = value
	
func get_value() -> int:
	return _Progressbar.value

func increment_value() -> void:
	_Progressbar.value += 1
