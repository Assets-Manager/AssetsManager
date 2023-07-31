extends StaticBody

export(String) var label : String = "" setget set_label

onready var _Label := $Label3D

signal pressed()

func set_label(value : String) -> void:
	label = value
	
	if _Label:
		_Label.text = value

func _ready() -> void:
	set_label(label)

func _on_OriginPoint_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == BUTTON_LEFT) && event.pressed:
			emit_signal("pressed")

func _on_OriginPoint_mouse_entered() -> void:
	_Label.visible = true

func _on_OriginPoint_mouse_exited() -> void:
	_Label.visible = false
