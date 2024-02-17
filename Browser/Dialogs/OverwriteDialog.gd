# In this dialog the user can decide how a new asset that is marked as already 
# existing should be treated.
extends WindowDialog

const CARD = preload("res://Browser/Dialogs/AssetInfoCard.tscn")

onready var _NewAsset := $MarginContainer/VBoxContainer/AssetInfoCard
onready var _Cards := $MarginContainer/VBoxContainer/ScrollContainer/Cards
onready var _OverwriteBtn := $MarginContainer/VBoxContainer/HBoxContainer/Overwrite
onready var _LinkBtn := $MarginContainer/VBoxContainer/HBoxContainer/Link

var _SelectedCard = null
var _ImportAsset : Dictionary = {}

# Sets the new asset info
func set_new_asset(thumb : Texture, asset : Dictionary) -> void:
	_NewAsset.thumbnail = thumb
	_ImportAsset = asset
	_NewAsset.text = _ImportAsset.file.get_file()
	
	_LinkBtn.visible = AssetsLibrary.current_directory != 0
	
	# Gets a list with all assets, which shares the same name
	var assets = AssetsLibrary.get_assets_by_name(_ImportAsset.file)
	for asset in assets:	# Add them to the dialog
		_add_asset(asset.id, AssetsLibrary.load_thumbnail(asset), asset.filename)

# Adds  to the 'Existing assets' list
func _add_asset(id : int, thumb : Texture, text : String) -> void:
	var tmp := CARD.instance()
	_Cards.add_child(tmp)
	tmp.id = id
	tmp.thumbnail = thumb
	tmp.text = text
	tmp.connect("selected", self, "_card_selected", [tmp])

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
		_LinkBtn.disabled = AssetsLibrary.is_asset_in_dir(card.id, AssetsLibrary.current_directory)

# Creates the asset as a new one.
func _on_New_pressed():
	_ImportAsset.status = AssetsLibrary.FileImportStatus.STATUS_OK
	AssetsLibrary.handle_user_processed_file(_ImportAsset)
	_on_Cancel_pressed()

func _on_Cancel_pressed():
	# Cleanup
	_ImportAsset = {}
	_SelectedCard = null
	_OverwriteBtn.disabled = true
	_LinkBtn.disabled = true
	_clear()
	
	hide()

# Overwrites a selected assets
func _on_Overwrite_pressed():
	_ImportAsset["overwrite_id"] = _SelectedCard.id
	AssetsLibrary.handle_user_processed_file(_ImportAsset)
	_on_Cancel_pressed()

# Links the selected asset with the current directory.
func _on_Link_pressed():
	AssetsLibrary.link_asset(AssetsLibrary.current_directory, _SelectedCard.id)
	_on_Cancel_pressed()
