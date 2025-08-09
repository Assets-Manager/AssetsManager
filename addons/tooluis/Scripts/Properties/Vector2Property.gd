@tool
extends VBoxContainer

signal value_changed(value)

@export var title: String = "": set = set_title
@export var value := Vector2.ZERO: set = set_value
@export var default_value := Vector2.ZERO
@export var enabled := true: set = set_enabled

@onready var _Name := $HBoxContainer3/Name
@onready var _Revert := $HBoxContainer3/Revert
@onready var _XValue := $HBoxContainer2/NumericEdit
@onready var _YValue := $HBoxContainer2/NumericEdit2

func set_title(val : String) -> void:
	title = val
	
	if _Name:
		_Name.text = tr(title)
		
func set_enabled(val : bool) -> void:
	enabled = val
	
	if _XValue:
		_XValue.editable = enabled
		_YValue.editable = enabled
		_Revert.disabled = !enabled

func _ready() -> void:
	_Name.text = tr(title)
	_Revert.icon = get_theme_icon("reload", "FileDialog")
	set_value(default_value)
	set_enabled(enabled)
	
	_XValue.connect("value_changed", Callable(self, "_vector_value_changed").bind(0))
	_YValue.connect("value_changed", Callable(self, "_vector_value_changed").bind(1))

func set_value(val : Vector2) -> void:
	value = val
	if !_XValue:
		return
	
	_XValue.value = val.x
	_YValue.value = val.y
	_Revert.visible = value != default_value

func _vector_value_changed(new_value : float, idx : int) -> void:
	value[idx] = new_value
	_Revert.visible = value != default_value
	
	emit_signal("value_changed", value)

func _on_Revert_pressed() -> void:
	set_value(default_value)
	emit_signal("value_changed", value)
