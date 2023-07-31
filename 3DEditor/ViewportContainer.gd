extends ViewportContainer

onready var _Viewport := $Viewport

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	
func _gui_input(event: InputEvent) -> void:
	_Viewport.input(event)
	_Viewport.unhandled_input(event)
