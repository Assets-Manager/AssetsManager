extends Node

const SETTINGS_DIR : String = "user://config"

var settings : Settings

func _ready() -> void:
	OS.set_window_title(ProjectSettings.get_setting("application/config/name") + " - " + ProjectSettings.get_setting("application/config/version"))
	
	_load_settings()
	
func _load_settings() -> void:
	var file : File = File.new()
	var configPath : String = SETTINGS_DIR.plus_file("settings.res")
	if file.file_exists(configPath):
		settings = load(configPath)
	else:
		settings = Settings.new()
		
func _exit_tree() -> void:
	var dir := Directory.new()
	if !dir.dir_exists(SETTINGS_DIR):
		dir.make_dir_recursive(SETTINGS_DIR)
		
	var configPath : String = SETTINGS_DIR.plus_file("settings.res")
	ResourceSaver.save(configPath, settings)
