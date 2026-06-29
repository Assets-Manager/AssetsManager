@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Autocomplete", "LineEdit", preload("res://addons/tooluis/Scripts/Autocomplete.gd"), null)


func _exit_tree():
	remove_custom_type("Autocomplete")
