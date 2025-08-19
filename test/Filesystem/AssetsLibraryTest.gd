# GdUnit generated TestSuite
class_name AssetsLibraryTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://Filesystem/AssetsLibrary.gd'

var _AssetLibrary = null

func before() -> void:
	_AssetLibrary = monitor_signals(load(__source).new())
	add_child(_AssetLibrary)
	
	var path = OS.get_temp_dir().path_join("test_asset_lib")
	if !DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)
	
	_AssetLibrary.open(path)

func test__files_dropped() -> void:
	_AssetLibrary._Thread = Thread.new()
	var files := DirAccess.get_files_at("res://Assets/Material Icons")
	_AssetLibrary._files_dropped(["res://Assets/Material Icons"])
	
	await assert_signal(_AssetLibrary).is_emitted("update_total_import_assets", [files.size() / 2])
	assert_int(_AssetLibrary._FileQueue.size()).is_equal(files.size() / 2)
	_AssetLibrary._Thread = null
	_AssetLibrary._FileQueue.clear()
