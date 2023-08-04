extends WindowDialog

onready var _Progressbar := $CenterContainer/VBoxContainer/ProgressBar

func _ready() -> void:
	get_close_button().hide()
	rect_size = rect_min_size
	
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
