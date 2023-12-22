extends Node

signal switch_view(viewer)
signal switch_home()

const VIEWERS_PATH = "res://Viewers/"

var _Viewers : Dictionary = {}
var _ViewersType : Dictionary = {}

func _ready():
	_load_plugins()
	
# Called by the control
func get_viewers() -> Array:
	var result : Array = []
	for k in _Viewers:
		result.append(_Viewers[k])
	return result
	
func show_main_window() -> void:
	emit_signal("switch_home")
	
func open_viewer(asset_id : int) -> int:
	var type : String = AssetsLibrary.get_asset_type(asset_id)
	if type in _ViewersType:
		var viewer : IViewer = _ViewersType[type]
		var result = viewer.load_asset(asset_id)
		if result == OK:
			emit_signal("switch_view", viewer)
		else:
			return result
	else:
		return FAILED
	
	return OK
	
func _load_plugins() -> void:
	for k in _Viewers:
		_Viewers[k].queue_free()
	
	_Viewers.clear()
	_ViewersType.clear()
	
	var viewer_dirs = []
	
	var dir := Directory.new()
	# Gets all viewer directories.
	if dir.open(VIEWERS_PATH) == OK:
		dir.list_dir_begin(true, true)
		var dir_name = dir.get_next()
		while dir_name != "":
			if dir.current_is_dir():
				viewer_dirs.append(VIEWERS_PATH + dir_name + "/")
				
			dir_name = dir.get_next()
			
	for viewer_dir in viewer_dirs:
		if dir.open(viewer_dir) == OK:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if !dir.current_is_dir():
					var script = load(viewer_dir + file_name.trim_suffix('.remap'))
					if script.is_class("GDScript"):
						var instance = script.new()
						if instance is ViewerPlugin:
							var mainscene = instance.get_main_scene()
							_Viewers[instance.get_viewer_name()] = mainscene
							for type in instance.get_supported_types():
								_ViewersType[type] = mainscene

				file_name = dir.get_next()
