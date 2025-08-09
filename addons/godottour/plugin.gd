@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("GodotTour", "Control", preload("GodotTour.gd"), null)

func _exit_tree() -> void:
	remove_custom_type("GodotTour")
