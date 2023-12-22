# Generic class to manage change history
class_name History
extends Reference

var _History = []
var _Cursor = -1
var _TopCursor = -1
var _CurrentUndo : Dictionary = {}

var max_elements : int = 25 setget set_max_elements

func set_max_elements(value : int) -> void:
	max_elements = value
	_History.resize(value)
	_Cursor = -1
	
func _init():
	_History.resize(max_elements)
	
func create_undo_action(name : String) -> void:
	_CurrentUndo["name"] = name
	
func add_do_method(object : Object, method : String, binding) -> void:
	if !("do_method" in _CurrentUndo):
		_CurrentUndo["do_method"] = []
	
	_CurrentUndo["do_method"].append({"self": object, "method": method, "binding": binding})
	
func add_undo_method(object : Object, method : String, binding) -> void:
	if !("undo_method" in _CurrentUndo):
		_CurrentUndo["undo_method"] = []
	
	_CurrentUndo["undo_method"].append({"self": object, "method": method, "binding": binding})

func add_do_property(object : Object, prop : String, value) -> void:
	if !("do_property" in _CurrentUndo):
		_CurrentUndo["do_property"] = []
	
	_CurrentUndo["do_property"].append({"self": object, "prop": prop, "value": value})
	
func add_undo_property(object : Object, prop : String, value) -> void:
	if !("undo_property" in _CurrentUndo):
		_CurrentUndo["undo_property"] = []
	
	_CurrentUndo["undo_property"].append({"self": object, "prop": prop, "value": value})
	
# Adds a new element on top of the history.
# Removes older elements if neccessary.
func commit_undo_action() -> void:
	if _Cursor >= _History.size():
		_History.remove(0)
	else:
		_Cursor += 1
	
	_History[_Cursor] = _CurrentUndo
	
	_TopCursor = _Cursor
	_CurrentUndo = {}

func can_go_back() -> bool:
	return _Cursor >= 0

func can_go_forward() -> bool:
	return _Cursor < _TopCursor

func go_back() -> void:
	if can_go_back():
		var history = _History[_Cursor]
		if "undo_property" in history:
			for prop in history["undo_property"]:
				(prop["self"] as Object).set(prop["prop"], prop["value"])
		
		if "undo_method" in history:
			for method in history["undo_method"]:
				(method["self"] as Object).call(method["method"], method["binding"])
			
		_Cursor -= 1
		
func go_forward() -> void:
	if can_go_forward():
		print(_Cursor)
		_Cursor += 1
		var history = _History[_Cursor]
		if "do_property" in history:
			for prop in history["do_property"]:
				(prop["self"] as Object).set(prop["prop"], prop["value"])
		
		if "do_method" in history:
			for method in history["do_method"]:
				(method["self"] as Object).call(method["method"], method["binding"])

func clear() -> void:
	_Cursor = -1
	_TopCursor = -1
	_History.clear()
	_History.resize(max_elements)
