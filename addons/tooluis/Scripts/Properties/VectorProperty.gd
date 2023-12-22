tool
extends VBoxContainer

signal value_changed(value)

export(String) var title = "" setget set_title
export(Vector3) var value := Vector3.ZERO setget set_value
export(Vector3) var default_value := Vector3.ZERO
export(bool) var enabled := true setget set_enabled

onready var _Name := $HBoxContainer3/Name
onready var _Revert := $HBoxContainer3/Revert
onready var _XValue := $HBoxContainer2/NumericEdit
onready var _YValue := $HBoxContainer2/NumericEdit2
onready var _ZValue := $HBoxContainer2/NumericEdit3

func set_title(val : String) -> void:
	title = val
	
	if _Name:
		_Name.text = tr(title)
		
func set_enabled(val : bool) -> void:
	enabled = val
	
	if _XValue:
		_XValue.editable = enabled
		_YValue.editable = enabled
		_ZValue.editable = enabled
		_Revert.disabled = !enabled

func _ready() -> void:
	_Name.text = tr(title)
	_Revert.icon = get_icon("reload", "FileDialog")
	set_enabled(enabled)
	set_value(default_value)
	
	_XValue.connect("value_changed", self, "_vector_value_changed", [0])
	_YValue.connect("value_changed", self, "_vector_value_changed", [1])
	_ZValue.connect("value_changed", self, "_vector_value_changed", [2])

func set_value(val : Vector3) -> void:
	value = val
	if !_XValue:
		return
	
	_XValue.release_focus()
	_YValue.release_focus()
	_ZValue.release_focus()
	
	_XValue.value = val.x
	_YValue.value = val.y
	_ZValue.value = val.z
	_Revert.visible = value != default_value

func _vector_value_changed(new_value : float, idx : int) -> void:
	value[idx] = new_value
	_Revert.visible = value != default_value
	
	_XValue.release_focus()
	_YValue.release_focus()
	_ZValue.release_focus()
	
	emit_signal("value_changed", value)

func _on_Revert_pressed() -> void:
	set_value(default_value)
	emit_signal("value_changed", value)
