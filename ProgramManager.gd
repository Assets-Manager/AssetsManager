extends Node

const SETTINGS_DIR : String = "user://config"

var settings : Settings

func _ready() -> void:
	get_window().set_title(ProjectSettings.get_setting("application/config/name") + " - " + ProjectSettings.get_setting("application/config/version"))
	
	_load_settings()
	
func _load_settings() -> void:
	var configPath : String = SETTINGS_DIR.path_join("settings.res")
	if FileAccess.file_exists(configPath):
		settings = load(configPath)
	else:
		settings = Settings.new()
		
func _exit_tree() -> void:
	#var dir := DirAccess.new()
	if !DirAccess.dir_exists_absolute(SETTINGS_DIR):
		DirAccess.make_dir_recursive_absolute(SETTINGS_DIR)
		
	var configPath : String = SETTINGS_DIR.path_join("settings.res")
	ResourceSaver.save(settings, configPath)
