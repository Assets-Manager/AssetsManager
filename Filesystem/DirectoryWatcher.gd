class_name DirectoryWatcher
extends Node

enum FileEvents {
	ADDED,
	REMOVED,
	MODIFIED,
	RENAMED_OLD,
	RENAMED_NEW
}

signal new_asset(path)
signal changed_asset(path)
signal deleted_asset(path)
signal renamed_asset(old_path, new_path)

onready var _DirWatcher : GDFilewatcher = GDFilewatcher.new()
var _OldName : String = ""
var paused : bool = false

var supported_extensions : Array = []

func _ready() -> void:
	_DirWatcher.connect("file_changed", self, "_file_changed", [], Object.CONNECT_DEFERRED)

func open(path : String) -> void:
	_DirWatcher.open(path)

func _file_changed(path : String, event : int) -> void:
	if (path.begins_with("thumbnail") || (supported_extensions.find(path.get_extension().to_lower()) == -1)) || paused:
		return
	
	match event:
		FileEvents.ADDED:
			emit_signal("new_asset", path)
		FileEvents.REMOVED:
			emit_signal("deleted_asset", path)
		FileEvents.MODIFIED:
			emit_signal("changed_asset", path)
		FileEvents.RENAMED_OLD:
			_OldName = path
		FileEvents.RENAMED_NEW:
			emit_signal("renamed_asset", _OldName, path)
			_OldName = ""
