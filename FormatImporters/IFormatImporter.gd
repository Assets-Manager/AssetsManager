class_name IFormatImporter
extends RefCounted

var _Library : Node
var _TypeId : int = -1

## Called by the AssetsLibrary
## Can be overwritten must call the base method
func register(library : Node, type_id : int) -> void:
	_Library = library
	_TypeId = type_id

## Returns the name of the type e.g.: Image
## Must be overwritten
static func get_type() -> String:
	return ""
	
## Returns the id of the type.
func get_type_id() -> int:
	return _TypeId
	
## Returns a list of supported file extensions.
## Must be overwritten
static func get_extensions() -> Array:
	return []

## Imports a new asset
func import(path: String, update_id : int) -> AMAsset:
	var thumbnail : Texture2D = render_thumbnail(path)
	var thumbnail_path : String = _Library.get_thumbnail_path().path_join(_generate_thumbnail_name(path))
	var can_proceed : bool = false
	
	# Saves the thumbnail to the drive
	if thumbnail:
		can_proceed = thumbnail.get_image().save_png(thumbnail_path) == OK
	else:
		can_proceed = true
	
	if can_proceed:
		path = _import_asset(path, update_id)
		if !path.is_empty():
			if update_id != 0:
				return _Library.update_asset(update_id, path, thumbnail_path.get_file() if thumbnail else null, get_type_id())
			else:
				var asset = _Library.add_asset(path, thumbnail_path.get_file() if thumbnail else null, get_type_id())
				if asset != null:
					return asset
			
		# On error remove the thumbnail
		DirAccess.remove_absolute(thumbnail_path)
	return null

## Generates a unique name for the thumbnail.
## The generated hash is only needed for a unique name and is not intended to be secure.
func _generate_thumbnail_name(path : String) -> String:
	return (path.get_file() + Time.get_datetime_string_from_datetime_dict(Time.get_datetime_dict_from_system(), false)).sha256_text() + ".png"

## Moves the file into the assets directory. [br]
## Can be overwritten [br]
## [b]Return:[/b] Returns the newly generated library path, or an empty string on error
func _import_asset(path : String, update_id : int) -> String:
	var newPath = _Library.generate_and_migrate_assets_path(path, update_id)
	if move_asset(path, newPath):
		return newPath
		
	return ""
	
## Moves an asset from a given path to the given destination
func move_asset(from: String, to: String) -> bool:
	return DirAccess.rename_absolute(from, to) == OK

## Renders the thumbnail of a given path.
## Called in sub-thread.
## Must be overwritten
## Params:
##	- path: Path of the file
## Returns the newly rendered thumbnail.
func render_thumbnail(path: String) -> Texture2D:
	return null
