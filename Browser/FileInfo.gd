extends MarginContainer

@onready var _Name := $ScrollContainer/VBoxContainer/ScrollContainer/VBoxContainer/Name
@onready var _TagMgr := $ScrollContainer/VBoxContainer/ScrollContainer/VBoxContainer/TagManager
@onready var _Save := $ScrollContainer/VBoxContainer/Save
@onready var _Authors := $ScrollContainer/VBoxContainer/ScrollContainer/VBoxContainer/Authors
@onready var _Licenses := $ScrollContainer/VBoxContainer/ScrollContainer/VBoxContainer/Licenses
@onready var _AuthorsLabel := $ScrollContainer/VBoxContainer/ScrollContainer/VBoxContainer/AuthorsLabel
@onready var _LicenseLabel := $ScrollContainer/VBoxContainer/ScrollContainer/VBoxContainer/LicenseLabel

var asset = null : set = _set_asset
var _currentTags : Array[AMTag] = []
var _currentAuthors : Array[AMAuthor] = []
var _currentLicenses : Array[AMLicense] = []

func _ready() -> void:
	_set_asset(asset)

func _set_asset(value) -> void:
	asset = value

	if _Name:
		if asset:
			_Name.text = asset.filename if asset is AMAsset else asset.name
			_currentTags = AssetsLibrary.get_tags(asset)
			
			_currentAuthors = []
			_currentLicenses = []
			_Authors.visible = asset is AMAsset
			_AuthorsLabel.visible = _Authors.visible
			
			_Licenses.visible = _Authors.visible
			_LicenseLabel.visible = _Authors.visible
			if asset is AMAsset:
				_currentAuthors = AssetsLibrary.get_authors(asset)
				for author in _currentAuthors:
					_Authors.chips.add_chip(author.name, author)
					
				_currentLicenses = AssetsLibrary.get_asset_licenses(asset)
				for license in _currentLicenses:
					_Licenses.chips.add_chip(license.name, license)
			
			_TagMgr.set_selected_tags(_currentTags.duplicate())

func _on_save_pressed() -> void:
	AssetsLibrary.rename(asset, _Name.text)
	var tags : Array[AMTag] = _TagMgr.get_selected_tags()
	var authors: Array[AMAuthor] = []
	authors.append_array(_Authors.chips.get_chips().map(func(chip): return chip.value))

	var licenses: Array[AMLicense] = []
	licenses.append_array(_Licenses.chips.get_chips().map(func(chip): return chip.value))

	var tags_to_remove : Array[AMTag] = []
	tags_to_remove.append_array(_currentTags.filter(func(current_tag): return !tags.any(func(tag): return current_tag.id == tag.id)))
	if !tags_to_remove.is_empty():
		AssetsLibrary.remove_tags([asset], tags_to_remove, false)
	
	var authors_to_remove: Array[AMAuthor] = []
	authors_to_remove.append_array(_currentAuthors.filter(func(current_author): return !authors.any(func(author): return current_author.id == author.id)))
	if !authors_to_remove.is_empty():
		AssetsLibrary.remove_authors_from_asset(asset, authors_to_remove)
	
	var licenses_to_remove: Array[AMLicense] = []
	licenses_to_remove.append_array(_currentLicenses.filter(func(current_license): return !licenses.any(func(license): return current_license.id == license.id)))
	if !licenses_to_remove.is_empty():
		AssetsLibrary.remove_licenses_from_asset(asset, licenses_to_remove)
	
	if !tags.is_empty():
		AssetsLibrary.add_tags([asset], tags, false)
		
	if !authors.is_empty():
		AssetsLibrary.add_authors_to_asset(asset, authors)
		
	if !licenses.is_empty():
		AssetsLibrary.add_licenses_to_asset(asset, licenses)
		
	_currentTags = tags
	
	_Save.disabled = true
	BrowserManager.refresh_ui()

func _on_tag_manager_changed() -> void:
	_Save.disabled = false

func _on_name_text_changed(_new_text: String) -> void:
	_Save.disabled = false

func _on_authors_changed() -> void:
	_Save.disabled = false

func _on_licenses_changed() -> void:
	_Save.disabled = false
