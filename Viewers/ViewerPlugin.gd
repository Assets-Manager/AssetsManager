class_name ViewerPlugin
extends Reference

var _Library : Node

# Called by the WindowManager
# Can be overwritten must call the base method
func register(library : Node) -> void:
	_Library = library

# Returns the name of the viewer, so that other formats can use already existing ones.
func get_viewer_name() -> String:
	return ""
	
# Returns a list of types this viewer is intended for. E.g.: ["Model"] for the 3d viewer
func get_supported_types() -> Array:
	return []

# Returns the main viewer scene.
func get_main_scene() -> IViewer:
	return null
