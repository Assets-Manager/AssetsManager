class_name Autocomplete extends LineEdit

class Option extends RefCounted:
	var display_text: String = ""
	var value: Variant

## Called everytime the user changes the text of the input.
## The programmer must set options.
signal request_options(text: String)

signal option_selected(value: Variant)

@export var total_visible_lines: int = 3
@export var show_popup_after_x_characters: int = 3
var options: Array[Option] = [] : set = _set_options

var _PopupVisible = false
var _TotalSize : int = 0
var _LinePos = 0

func _ready() -> void:
	text_changed.connect(_text_changed)
	focus_entered.connect(_focus_entered)
	focus_exited.connect(_focus_exited)

func _set_options(value: Array[Option]) -> void:
	options = value
	_TotalSize = 0
	_LinePos = 0
	
	var font = get_theme_font("font")
	for option in options:
		_TotalSize = maxi(font.get_string_size(option.display_text).x, _TotalSize)
	
	if (text.length() >= show_popup_after_x_characters) && (options.size() > 0):
		_PopupVisible = true
	else:
		_PopupVisible = false
	
	queue_redraw()

func _focus_entered() -> void:
	if text.length() >= show_popup_after_x_characters:
		request_options.emit(text)

func _focus_exited() -> void:
	if _PopupVisible:
		_PopupVisible = false
		queue_redraw()

func _text_changed(new_text: String) -> void:
	if new_text.length() >= show_popup_after_x_characters:
		request_options.emit(new_text)
	
func _gui_input(event: InputEvent) -> void:
	if _PopupVisible:
		if Input.is_action_pressed("ui_down"):
			_LinePos = wrapi(_LinePos + 1, 0, options.size())
			accept_event()
			queue_redraw()
		elif Input.is_action_pressed("ui_up"):
			_LinePos = wrapi(_LinePos - 1, 0, options.size())
			accept_event()
			queue_redraw()
		elif Input.is_action_pressed("ui_accept"):
			if _LinePos < options.size():
				var option = options[_LinePos]
				text = option.display_text
				_PopupVisible = false
				option_selected.emit(option.value)
				accept_event()
				queue_redraw()

func _draw() -> void:
	if _PopupVisible:
		var font = get_theme_font("font")
		var panel = get_theme_stylebox("panel", "Autocomplete")
		var row_height = font.get_ascent() + font.get_descent()
		
		var popup_height = row_height * mini(total_visible_lines, options.size())
		var popup_width = maxi(_TotalSize, size.x)
		var posx = 0
		
		if (global_position.x + popup_width) > get_viewport_rect().size.x:
			var size := get_viewport_rect().size
			size.x -= popup_width
			
			size = make_canvas_position_local(size)
			posx = size.x
			if posx < get_viewport_rect().position.x:
				posx = 0
		
		draw_style_box(panel, Rect2i(Vector2i(posx, size.y), Vector2i(popup_width, popup_height)))
		
		var half_lines := total_visible_lines / 2
		var offset = clampi(_LinePos - half_lines, 0, options.size() - (total_visible_lines - half_lines) - 1)

		var highlight = get_theme_stylebox("highlight", "Autocomplete")
		draw_style_box(highlight, Rect2i(Vector2i(position.x, size.y + (_LinePos - offset) * row_height), Vector2i(size.x, row_height)))

		var margin_left = get_theme_constant("margin_left", "Autocomplete")

		var posy = size.y
		for i in range(total_visible_lines):
			if (i + offset) >= options.size():
				break
			
			var option := options[i + offset]
			posy += font.get_ascent()
			draw_string(font, Vector2i(margin_left, posy), option.display_text)
			posy += font.get_descent()
