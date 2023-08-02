extends Node

const SQLITE = preload("res://addons/godot-sqlite/godot-sqlite-wrapper.gd")

var _DB : SQLITE = null

# Opens a database
# Returns true on success.
func open(path : String) -> bool:
	_DB = SQLITE.new()
	_DB.path = path
	if _DB.open_db():
		_migrate()		# Starts a migration of the database
		return true
		
	return false

func query_assets(search : String, page : int, limit : int) -> void:
	if _DB:
		if _DB.query_with_bindings("SELECT * FROM assets WHERE name LIKE '%?%' LIMIT ?, ?;", [search, page, limit]):
			print(_DB.query_result_by_reference)

func _migrate() -> void:
	pass
