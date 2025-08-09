@tool
extends LineEdit

enum ValueType {
	INTEGER,
	FLOAT
}

signal value_changed(value)

@export var value := 0.0: set = set_value
@export var value_type := ValueType.INTEGER

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			release_focus()
	elif event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT) and event.pressed:
			await get_tree().idle_frame
			select_all()
			
	#accept_event()

func set_value(val : float) -> void:
	value = val
	text = str(value)

func _ready() -> void:
	text = str(value)

func _on_text_entered(new_text: String) -> void:
	_check_value()

func _on_focus_exited() -> void:
	_check_value()

func _check_value():
	var val : float = 0.0
	var value_ok := false
	
	match value_type:
		ValueType.INTEGER:
			if text.is_valid_int():
				val = int(text)
				value_ok = true
		ValueType.FLOAT:
			if text.is_valid_float():
				val = float(text)
				value_ok = true
	
	if value_ok:
		if val != value:
			value = val
			text = str(value)
			emit_signal("value_changed", value)
	else:
		text = str(value)
