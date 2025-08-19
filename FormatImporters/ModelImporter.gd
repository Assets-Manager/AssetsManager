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
	
func move_asset(from: String, to: String) -> bool:
	if super.move_asset(from, to):
		if from.get_extension().to_lower() == "obj":
			if DirAccess.rename_absolute(from.get_basename() + ".mtl", to.get_basename() + ".mtl") == OK:
				return true
		return true
	return false
	
func render_thumbnail(path: String) -> Texture2D:
	return _Preview.generate(path)
