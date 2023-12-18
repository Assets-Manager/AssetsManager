tool
class_name GodotTour
extends Control

signal tour_finished()

const TOUR_STEP = preload("TourStep.gd")

export(Array, Resource) var steps : Array setget set_steps

onready var _TutorialDialog : AcceptDialog = AcceptDialog.new()
onready var _Outline : ReferenceRect = ReferenceRect.new()
var _PreviousButton : Button

var _Running : bool = false
var _Step : int = 0

func _ready() -> void:
	add_child(_Outline)
	add_child(_TutorialDialog)
	
	_TutorialDialog.connect("confirmed", self, "_confirmed")
	_TutorialDialog.connect("custom_action", self, "_custom_action")
	
	_PreviousButton = _TutorialDialog.add_button("Previous", false, "prev")
	_PreviousButton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_TutorialDialog.get_ok().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	_Outline.editor_only = false
	_Outline.border_color = Color("#dc7412")
	_Outline.border_width = 2
	_Outline.hide()
	
	_TutorialDialog.popup_exclusive = true
	anchor_bottom = 1
	anchor_right = 1
	
	if !Engine.editor_hint:
		get_viewport().connect("size_changed", self, "_size_changed_2")
		connect("resized", self, "_size_changed_2")

func start() -> void:
	if !steps.empty():
		_Running = true
		_Step = 0
		
		_popup_dialog()

func _confirmed() -> void:
	if _Step == (steps.size() - 1):
		_Outline.hide()
		hide()
		emit_signal("tour_finished")
	else:
		_Step += 1
		_popup_dialog()

func _custom_action(action : String) -> void:
	if _Step > 0:
		_Step -= 1
		_popup_dialog()

func _popup_dialog() -> void:
	var step = steps[_Step]
	_TutorialDialog.dialog_text = step.text.replace("\\n", "\n")
	
	if _Step == 0:
		_PreviousButton.hide()
	else:
		_PreviousButton.show()
		
	if _Step == (steps.size() - 1):
		_TutorialDialog.get_ok().text = "Finish"
	else:
		_TutorialDialog.get_ok().text = "Next"
	
	if step.control:
		var control : Control = get_node(step.control)
		var pos : Vector2 = control.rect_global_position + control.rect_size
		
		_Outline.rect_position = control.rect_global_position
		_Outline.rect_size = control.rect_size
		
		_TutorialDialog.rect_position = pos
		_TutorialDialog.rect_size = Vector2.ONE
		_TutorialDialog.popup()
		_Outline.show()
	else:
		_Outline.hide()
		_TutorialDialog.popup_centered()

func set_steps(value : Array) -> void:
	steps = value
	for i in steps.size():
		if !steps[i]:
			steps[i] = TOUR_STEP.new()

func _size_changed_2() -> void:
	if !steps.empty() and _Running:
		call_deferred("_popup_dialog")
