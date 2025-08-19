extends MarginContainer

@onready var _Name := $ScrollContainer/VBoxContainer/Name
@onready var _TagMgr := $ScrollContainer/VBoxContainer/TagManager
@onready var _Save := $ScrollContainer/VBoxContainer/Save

var asset = null : set = _set_asset
var _currentTags : Array[AMTag] = []

func _ready() -> void:
	_set_asset(asset)

func _set_asset(value) -> void:
	asset = value

	if _Name:
		if asset:
			_Name.text = asset.filename if asset is AMAsset else asset.name
			_currentTags = AssetsLibrary.get_tags(asset)
			_TagMgr.set_selected_tags(_currentTags.duplicate())

func _on_save_pressed() -> void:
	AssetsLibrary.rename(asset, _Name.text)
	var tags : Array[AMTag] = _TagMgr.get_selected_tags()
	var tags_to_remove : Array[AMTag] = []
	for current_tag in _currentTags:
		var found = false
		for tag in tags:
			if current_tag.id == tag.id:
				found = true
				break
		if !found:
			tags_to_remove.push_back(current_tag)
	
	if !tags_to_remove.is_empty():
		AssetsLibrary.remove_tags([asset], tags_to_remove, false)
	
	AssetsLibrary.add_tags([asset], tags, false)
	_currentTags = tags
	
	_Save.disabled = true
	BrowserManager.refresh_ui()

func _on_tag_manager_changed() -> void:
	_Save.disabled = false

func _on_name_text_changed(new_text: String) -> void:
	_Save.disabled = false
