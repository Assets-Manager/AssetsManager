class_name IFormatImporter
extends Reference

var _Library : Node
var _TypeId : int = -1
var _Directory : Directory = Directory.new()

# Called by the AssetsLibrary
# Can be overwritten must call the base method
func register(library : Node, type_id : int) -> void:
	_Library = library
	_TypeId = type_id

# Returns the name of the type e.g.: Image
# Must be overwritten
static func get_type() -> String:
	return ""
	
# Returns the id of the type.
func get_type_id() -> int:
	return _TypeId
	
# Returns a list of supported file extensions.
# Must be overwritten
static func get_extensions() -> Array:
	return []

# Imports a new asset
func import(path: String, update_id : int) -> Dictionary:
	var thumbnail : Texture = render_thumbnail(path)
	var thumbnail_path : String = _Library.get_thumbnail_path() + "/" + _generate_thumbnail_name(path)
	var can_proceed : bool = false
	
	# Saves the thumbnail to the drive
	if thumbnail:
		can_proceed = thumbnail.get_data().save_png(thumbnail_path) == OK
	else:
		can_proceed = true
	
	if can_proceed:
		if _import_asset(path, update_id) == OK:
			path = _Library.generate_and_migrate_assets_path(path, update_id)
			if update_id != 0:
				if !_Library.update_asset(update_id, path, thumbnail_path.get_file() if thumbnail else null, get_type_id()):
					return {}
			else:
				update_id = _Library.add_asset(path, thumbnail_path.get_file() if thumbnail else null, get_type_id())
			
			if update_id != 0:
				var decoded_file = _Library.decode_asset_name(path)
				return {"id": update_id, "name": decoded_file[1], "thumbnail": thumbnail}
		_Directory.remove(thumbnail_path)
	return {}

# Generates a unique name for the thumbnail.
# The generated hash is only needed for a unique name and is not intended to be secure.
func _generate_thumbnail_name(path : String) -> String:
	return (path.get_file() + Time.get_datetime_string_from_datetime_dict(Time.get_datetime_dict_from_system(), false)).sha256_text() + ".png"

# Moves the file into the assets directory.
# Can be overwritten
func _import_asset(path : String, update_id : int) -> int:
	return _Directory.rename(path, _Library.generate_and_migrate_assets_path(path, update_id))

# Renders the thumbnail of a given path.
# Called in sub-thread.
# Must be overwritten
# Params:
#	- path: Path of the file
# Returns the newly rendered thumbnail.
func render_thumbnail(path: String) -> Texture:
	return null
