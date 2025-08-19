# In this dialog the user can decide how a new asset that is marked as already 
# existing should be treated.
extends Window

const CARD = preload("res://Browser/Dialogs/AssetInfoCard.tscn")

@onready var _NewAsset := $MarginContainer/VBoxContainer/AssetInfoCard
@onready var _Cards := $MarginContainer/VBoxContainer/ScrollContainer/Cards
@onready var _OverwriteBtn := $MarginContainer/VBoxContainer/HBoxContainer/Overwrite
@onready var _LinkBtn := $MarginContainer/VBoxContainer/HBoxContainer/Link

var _SelectedCard = null
var _ImportAsset : AMImportFile = null

# Sets the new asset info
func set_new_asset(thumb : Texture2D, asset : AMImportFile) -> void:
	_NewAsset.thumbnail = thumb
	_ImportAsset = asset
	_NewAsset.text = _ImportAsset.file.get_file()
	
	_LinkBtn.visible = _directory_id() != 0
	
	# Gets a list with all assets, which shares the same name
	var assets: Array[AMAsset] = AssetsLibrary.get_assets_by_name(_ImportAsset.file)
	for dbasset in assets:	# Add them to the dialog
		_add_asset(dbasset.id, AssetsLibrary.load_thumbnail(dbasset), dbasset.filename)

func _directory_id() -> int:
	if _ImportAsset.parent_id != 0:
		return _ImportAsset.parent_id
		
	return AssetsLibrary.current_directory

# Adds  to the 'Existing assets' list
func _add_asset(id : int, thumb : Texture2D, text : String) -> void:
	var tmp := CARD.instantiate()
	_Cards.add_child(tmp)
	tmp.id = id
	tmp.thumbnail = thumb
	tmp.text = text
	tmp.connect("selected", Callable(self, "_card_selected").bind(tmp))

# Clears all cards.
func _clear() -> void:
	for c in _Cards.get_children():
		c.queue_free()

func _card_selected(card) -> void:
	if card == _SelectedCard:
		return
	
	# Deselect the old card.
	if _SelectedCard:
		_SelectedCard.selected = false
	
	_SelectedCard = card
	_OverwriteBtn.disabled = false
	
	# Checks if the selected asset isn't already in the current directory.
	if _LinkBtn.visible:
		_LinkBtn.disabled = AssetsLibrary.is_asset_in_dir(card.id, _directory_id())

# Creates the asset as a new one.
func _on_New_pressed():
	_ImportAsset.status = AssetsLibrary.FileImportStatus.STATUS_OK
	AssetsLibrary.handle_user_processed_file(_ImportAsset)
	_on_Cancel_pressed()

func _on_Cancel_pressed():
	# Cleanup
	_ImportAsset = null
	_SelectedCard = null
	_OverwriteBtn.disabled = true
	_LinkBtn.disabled = true
	_clear()
	
	hide()

# Overwrites a selected assets
func _on_Overwrite_pressed():
	_ImportAsset.overwrite_id = _SelectedCard.id
	AssetsLibrary.handle_user_processed_file(_ImportAsset)
	_on_Cancel_pressed()

# Links the selected asset with the current directory.
func _on_Link_pressed():
	AssetsLibrary.move(_SelectedCard, _directory_id(), true)
	_on_Cancel_pressed()
