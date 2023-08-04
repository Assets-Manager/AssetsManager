extends Node

signal new_asset_added(name, thumbnail)
signal update_total_import_assets(count)

const PREVIEW = preload("res://Preview/Preview.tscn")
const SUPPORTED_FORMATS = []

const MODEL_FORMATS = [
	"gltf", "glb", 
	"obj", 
	"fbx"
]

const IMAGE_FORMATS = [
	"png", 
	"jpg", "jpeg", 
	"bmp", 
	"hdr", 
	"exr", 
	"svg", "svgz",
	"tga", 
	"webp"
]

var _AssetsPath : String = ""
var _QueueLock : Mutex = Mutex.new()
var _Thread : Thread = null
var _FileQueue : Array = []
var _TotalFilecount : int = 0
var _Preview
var _QuitThread : bool = false
var _Directory : Directory = Directory.new()

func _ready() -> void:
	SUPPORTED_FORMATS.append_array(MODEL_FORMATS)
	SUPPORTED_FORMATS.append_array(IMAGE_FORMATS)
	
	_Preview = PREVIEW.instance()
	add_child(_Preview)
	
func _exit_tree() -> void:
	_QuitThread = true
	if _Thread:
		_Thread.wait_to_finish()
	
# Opens a given assets library
# Returns true on success
func open(path : String) -> bool:
	_AssetsPath = path
	
	if _AssetsPath[_AssetsPath.length() - 1] == "/":
		_AssetsPath.erase(_AssetsPath.length() - 1, 1)
	
	if AssetsDatabase.open(_AssetsPath + "/assets.db"):
		get_tree().connect("files_dropped", self, "_files_dropped")
		return true
		
	return false
	
func query_assets(directoryId : int, search: String, skip: int, count: int) -> Array:
	var results := AssetsDatabase.query_assets(directoryId, search, skip, count)
	
	for result in results:
		if result.has("thumbnail"):
			var thumbnailpath = ""
			if result["thumbnail"]:
				thumbnailpath = _AssetsPath + "/thumbnails/" + result["thumbnail"]
			else:
				thumbnailpath = _AssetsPath + "/" + result["name"]
				
			var img := Image.new()
			img.load(thumbnailpath)
			
			var texture := ImageTexture.new()
			texture.create_from_image(img, 0)
			result["thumbnail"] = texture
			result["name"] = result["name"].get_basename().get_file()
	
	return results
	
func get_assets_count(directoryId : int, search : String) -> int:
	return AssetsDatabase.get_assets_count(directoryId, search)

func _process(_delta: float) -> void:
	if _Thread && !_Thread.is_alive():
		_Thread.wait_to_finish()
		_Thread = null

# Render and index thread for assets
func _render_and_index_thread(_unused : Object) -> void:
	var f : File = File.new()
	while !_QuitThread:
		_QueueLock.lock()
		var file : String = _FileQueue.pop_front()
		_QueueLock.unlock()
		
		if f.file_exists(file):
			var type : String = file.get_extension()
			var texture : Texture = null
			if MODEL_FORMATS.find(type) != -1:
				texture = _render_and_index_3d_model(file)
			elif IMAGE_FORMATS.find(type) != -1:
				texture = _render_and_index_image(file)
			
			if texture:
				emit_signal("new_asset_added", file.get_basename().get_file(), texture)

func _render_and_index_image(file : String) -> Texture:
	if AssetsDatabase.add_asset(file, null, AssetsDatabase.AssetType.IMAGE):
		_Directory.rename(file, _AssetsPath + "/" + file.get_file())
		
		var img := Image.new()
		img.load(_AssetsPath + "/" + file.get_file())
		
		var texture := ImageTexture.new()
		texture.create_from_image(img, 0)
		
		return texture
		
	return null

func _render_and_index_3d_model(file : String) -> Texture:
	# Just for a unique name, and not for security!
	var thumbnailName : String = (file.get_file() + Time.get_datetime_string_from_datetime_dict(Time.get_datetime_dict_from_system(), false)).sha256_text() + ".png"
	if AssetsDatabase.add_asset(file, thumbnailName, AssetsDatabase.AssetType.MODEL):
		var texture : Texture = _Preview.generate(file)
		
		# Creates the thumbnail directory.
		if !_Directory.dir_exists(_AssetsPath + "/thumbnails"):
			_Directory.make_dir(_AssetsPath + "/thumbnails")

		# Saves the newly generated thumbnail
		texture.get_data().save_png(_AssetsPath + "/thumbnails/" + thumbnailName)
		
		# Moves the file into the assets library folder.
		_Directory.rename(file, _AssetsPath + "/" + file.get_file())
		
		# Also move the mtl of obj files
		if file.get_extension().to_lower() == "obj":
			_Directory.rename(file.get_basename() + ".mtl", _AssetsPath + "/" + file.get_basename().get_file() + ".mtl")
		
		return texture
	
	return null

# Newly dropped files
func _files_dropped(files: PoolStringArray, _screen: int) -> void:
	var newFiles = []
	var f : File = File.new()
	for file in files:
		if f.file_exists(file) && (SUPPORTED_FORMATS.find(file.get_extension().to_lower()) != -1):
			newFiles.append(file)
	
	# No supported files found.
	if newFiles.empty():
		return
		
	# Updates the ui
	_TotalFilecount += newFiles.size()
	emit_signal("update_total_import_assets", _TotalFilecount)
	
	# Adds the new files to the queue
	_QueueLock.lock()
	_FileQueue.append_array(newFiles)
	_QueueLock.unlock()
	
	# Starts a new thread, but only if no one is already running.
	if !_Thread:
		_Thread = Thread.new()
		_Thread.start(self, "_render_and_index_thread", null)
