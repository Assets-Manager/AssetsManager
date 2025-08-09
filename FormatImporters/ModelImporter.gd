extends IFormatImporter

const PREVIEW = preload("res://Preview/Preview.tscn")
var _Preview

func register(library : Node, type_id : int) -> void:
	super.register(library, type_id)
	_Preview = PREVIEW.instantiate()
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
	
func _import_asset(path : String, update_id : int) -> int:
	var ret : int = super._import_asset(path, update_id)
	if (ret == OK) && (path.get_extension().to_lower() == "obj"):
		ret = DirAccess.rename_absolute(path.get_basename() + ".mtl", _Library.generate_and_migrate_assets_path(path.get_basename().get_file() + ".mtl", update_id))
	return ret
	
func render_thumbnail(path: String) -> Texture2D:
	return _Preview.generate(path)
