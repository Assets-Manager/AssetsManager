class_name Chips extends Panel

## Called everytime the user changes the text of the input.
## The programmer must set options.
signal request_options(text: String)

signal chip_added(chip: Chip)
signal chip_removed(chip: Chip)

const CHIP = preload("res://addons/tooluis/Scenes/Chip.tscn")

@onready var _Chips := $Chips
@onready var _Text := $Chips/Text

var options: Array[Autocomplete.Option] = [] : set = _set_options

func _set_options(value: Array[Autocomplete.Option]) -> void:
	options = value
	_Text.options = value

func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text.is_empty():
		_focus_text()
		return
	
	_add_chip(new_text, null)
	
func get_chips() -> Array[Chip]:
	var result : Array[Chip] = []
	for child in _Chips.get_children():
		if child is Chip && !child.is_queued_for_deletion():
			result.push_back(child)
			
	return result
	
func clear() -> void:
	for c in _Chips.get_children():
		if c is Chip:
			c.queue_free()
	
func add_chip(new_text: String, value: Variant) -> void:
	var tmp := CHIP.instantiate()
	tmp.text = new_text
	tmp.value = value
	tmp.remove_request.connect(_chip_remove.bind(tmp))
	
	_Chips.add_child(tmp)
	_Chips.move_child(tmp, _Chips.get_child_count() - 2)
	
func _add_chip(new_text: String, value: Variant) -> void:
	add_chip(new_text, value)
	_Text.text = ""
	_focus_text()
	chip_added.emit(_Chips.get_child(_Chips.get_child_count() - 2))
	
func _focus_text() -> void:
	_Text.release_focus()
	_Text.call_deferred("grab_focus")
	
func _calculate_size() -> void:
	var minimun_size : Vector2 = _Chips.get_minimum_size()
	custom_minimum_size.y = minimun_size.y if minimun_size.y > 0 else 33
	size.y = custom_minimum_size.y

func _chip_remove(chip: Chip) -> void:
	chip.queue_free()
	chip_removed.emit(chip)

func _on_chips_sort_children() -> void:
	if _Chips:
		_calculate_size()

func _on_text_request_options(text: String) -> void:
	request_options.emit(text)

func _on_text_option_selected(value: Variant) -> void:
	_add_chip(_Text.text, value)
