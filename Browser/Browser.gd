extends VBoxContainer

const CARD = preload("res://Browser/Card.tscn")

const SUPPORTED_FORMATS = ["gltf", "glb", "obj", "fbx"]

onready var _Preview := $Preview
onready var _Cards := $ScrollContainer/CenterContainer/Cards
onready var _ImporterDialog := $CanvasLayer/ImporterDialog

var _Threads : Array = []
var _TreeLock : Mutex = Mutex.new()

func _ready() -> void:
	get_tree().connect("files_dropped", self, "_files_dropped")
	
func _render_preview_thread(files: Array) -> void:
	var f : File = File.new()
	for file in files:
		if f.file_exists(file) && (SUPPORTED_FORMATS.find(file.get_extension().to_lower()) != -1):
			var texture : Texture = _Preview.generate(file)
			
			_TreeLock.lock()
			var tmp := CARD.instance()
			_Cards.add_child(tmp)
			tmp.set_texture(texture)
			tmp.set_title(file.get_basename().get_file())
			_ImporterDialog.increment_value()
			_TreeLock.unlock()
	
func _process(delta: float) -> void:
	if !_Threads.empty():
		var newThreadList = []
		for thread in _Threads:
			if !thread.is_alive():
				thread.wait_to_finish()
			else:
				newThreadList.append(thread)
		_Threads = newThreadList
	elif _ImporterDialog.visible:
		_ImporterDialog.hide()
	
func _files_dropped(files: PoolStringArray, screen: int) -> void:
	_TreeLock.lock()
	
	var newFiles = []
	var f : File = File.new()
	for file in files:
		if f.file_exists(file) && (SUPPORTED_FORMATS.find(file.get_extension().to_lower()) != -1):
			newFiles.append(file)
	
	if newFiles.empty():
		_TreeLock.unlock()
		return
	
	if !_ImporterDialog.visible:
		_ImporterDialog.set_value(0)
		_ImporterDialog.set_total_files(newFiles.size())
		_ImporterDialog.popup_centered()
	else:
		_ImporterDialog.set_total_files(_ImporterDialog.get_total_files() + newFiles.size())
	
	var thread := Thread.new()
	thread.start(self, "_render_preview_thread", newFiles)
	_Threads.push_back(thread)
	_TreeLock.unlock()
