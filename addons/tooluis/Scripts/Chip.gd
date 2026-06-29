class_name Chip extends Panel

signal remove_request()

@onready var _Text := $MarginContainer/HBoxContainer/Text
@onready var _Margin := $MarginContainer

var text : String = "" : set = _set_text
var value: Variant = null

func _ready() -> void:
	_set_text(text)

func _set_text(value: String) -> void:
	text = value
	if _Text:
		tooltip_text = text
		_Text.text = text

func _calculate_size() -> void:
	if get_parent().size.x < _Margin.size.x:
		_Text.clip_text = true
	
	custom_minimum_size.x = min(_Margin.size.x, get_parent().size.x)
	size.x = custom_minimum_size.x

func _on_button_pressed() -> void:
	remove_request.emit()

func _on_text_item_rect_changed() -> void:
	if _Margin:
		_calculate_size()
