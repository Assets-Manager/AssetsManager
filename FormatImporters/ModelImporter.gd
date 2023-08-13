extends IFormatImporter

const PREVIEW = preload("res://Preview/Preview.tscn")
var _Preview

func register(library : Node, type_id : int) -> void:
	.register(library, type_id)
	_Preview = PREVIEW.instance()
	_Library.add_child(_Preview)

# Returns the name of the type e.g.: Image
static func get_type() -> String:
	return "Model"
	
# Returns a list of supported file extensions.
static func get_extensions() -> Array:
	return [
		"gltf", "glb", 
		"obj", 
		"fbx"
	]
	
func _import_asset(path : String) -> int:
	var ret : int = ._import_asset(path)
	if (ret == OK) && (path.get_extension().to_lower() == "obj"):
		ret = _Directory.rename(path.get_basename() + ".mtl", _Library.build_assets_path(path.get_basename().get_file() + ".mtl"))
	return ret
	
func _render_thumbnail(path: String) -> Texture:
	return _Preview.generate(path)
