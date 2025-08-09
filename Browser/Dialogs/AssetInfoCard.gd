class_name AssetInfoCard extends HBoxContainer

signal selected()

@export var selectable : bool = true: set = _set_selectable

@onready var _Thumb := $TextureRect
@onready var _Text := $Label

var id : int = 0
var thumbnail : Texture2D: set = _set_texture
var text : String: set = _set_text

var selected_state : bool = false: set = _set_selected_state

func _set_selectable(val : bool) -> void:
	selectable = val
	
	if !selectable:
		mouse_default_cursor_shape = CURSOR_ARROW
	else:
		mouse_default_cursor_shape = CURSOR_POINTING_HAND

func _set_selected_state(val : bool) -> void:
	selected_state = val
	queue_redraw()

func _set_texture(val : Texture2D) -> void:
	thumbnail = val
	_Thumb.texture = thumbnail

func _set_text(val : String) -> void:
	text = val
	_Text.text = text
	
func _gui_input(event):
	if event is InputEventMouseButton && selectable:
		if event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
			_set_selected_state(true)
			emit_signal("selected")

func _draw():
	if selected:
		var stylebox : StyleBox = get_theme_stylebox("bg_selected", "AssetInfoCard")
		if stylebox:
			stylebox.draw(get_canvas_item(), Rect2(Vector2(), size))
