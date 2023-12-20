extends ViewerPlugin

const MAIN_VIEWER = preload("res://Viewers/3DEditor/AssetsViewer.tscn")

func get_viewer_name() -> String:
	return "3dEditor"

func get_supported_types() -> Array:
	return ["Model"]

func get_main_scene() -> IViewer:
	return MAIN_VIEWER.instance() as IViewer
