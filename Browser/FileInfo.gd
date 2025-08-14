extends MarginContainer

@onready var _Name := $ScrollContainer/VBoxContainer/Name
@onready var _TagMgr := $ScrollContainer/VBoxContainer/TagManager
@onready var _Save := $ScrollContainer/VBoxContainer/Save

var asset = null : set = _set_asset

func _ready() -> void:
	_set_asset(asset)

func _set_asset(value) -> void:
	asset = value

	if _Name:
		if asset:
			_Name.text = asset.filename if asset is AMAsset else asset.name
			_TagMgr.set_selected_tags(AssetsLibrary.get_tags(asset))

func _on_save_pressed() -> void:
	AssetsLibrary.rename(asset.id, _Name.text, asset is AMDirectory)
	AssetsLibrary.add_tags([asset], _TagMgr.get_selected_tags(), false)
	
	_Save.disabled = true
	BrowserManager.refresh_ui()

func _on_tag_manager_changed() -> void:
	_Save.disabled = false

func _on_name_text_changed(new_text: String) -> void:
	_Save.disabled = false
