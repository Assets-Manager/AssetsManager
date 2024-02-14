class_name AssetInfoCard
extends HBoxContainer

signal selected()

export var selectable : bool = true setget _set_selectable

onready var _Thumb := $TextureRect
onready var _Text := $Label

var id : int = 0
var thumbnail : Texture setget _set_texture
var text : String setget _set_text

var selected : bool = false setget _set_selected

func _set_selectable(val : bool) -> void:
	selectable = val
	
	if !selectable:
		mouse_default_cursor_shape = CURSOR_ARROW
	else:
		mouse_default_cursor_shape = CURSOR_POINTING_HAND

func _set_selected(val : bool) -> void:
	selected = val
	update()

func _set_texture(val : Texture) -> void:
	thumbnail = val
	_Thumb.texture = thumbnail

func _set_text(val : String) -> void:
	text = val
	_Text.text = text
	
func _gui_input(event):
	if event is InputEventMouseButton && selectable:
		if event.pressed && event.button_index == BUTTON_LEFT:
			_set_selected(true)
			emit_signal("selected")

func _draw():
	if selected:
		var stylebox : StyleBox = get_stylebox("bg_selected", "AssetInfoCard")
		if stylebox:
			stylebox.draw(get_canvas_item(), Rect2(Vector2(), rect_size))
