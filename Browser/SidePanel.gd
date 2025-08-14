extends Panel

signal closed()

@onready var _VBox = $VBoxContainer

@export var views : Dictionary[String, PackedScene]

var _CurrentTween : Tween = null

func _ready() -> void:
	size_flags_stretch_ratio = 0.0
	
func is_open() -> bool:
	return size_flags_stretch_ratio != 0.0
	
func create_instance(p_name: String) -> Control:
	if is_open():
		_VBox.get_child(_VBox.get_child_count() - 1).queue_free()
	
	if views.has(p_name):
		var view : Control = views[p_name].instantiate()
		_VBox.add_child(view)
		view.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		_kill_tween()
		_CurrentTween = create_tween()
		_CurrentTween.tween_property(self, "size_flags_stretch_ratio", 0.3, 0.2)
		
		return view
	else:
		printerr("Unknown view %s" % p_name)
		
	return null
	
func show_view(p_name: String) -> Control:
	if is_open():
		_on_close_pressed()
		return null
	
	return create_instance(p_name)

func _kill_tween() -> void:
	if _CurrentTween:
		_CurrentTween.kill()
		_CurrentTween = null

func _on_close_pressed() -> void:
	_kill_tween()
	_CurrentTween = create_tween()
	_CurrentTween.tween_property(self, "size_flags_stretch_ratio", 0.0, 0.2)
	await _CurrentTween.finished
	_VBox.get_child(_VBox.get_child_count() - 1).queue_free()
	emit_signal("closed")
