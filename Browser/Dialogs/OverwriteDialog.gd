extends WindowDialog

signal create_new_asset()
signal overwrite(id)

const CARD = preload("res://Browser/Dialogs/AssetInfoCard.tscn")

onready var _NewAsset := $MarginContainer/VBoxContainer/AssetInfoCard
onready var _Cards := $MarginContainer/VBoxContainer/ScrollContainer/Cards
onready var _OverwriteBtn := $MarginContainer/VBoxContainer/HBoxContainer/Overwrite

var _SelectedCard = null

# Sets the new asset info
func set_new_asset(thumb : Texture, text : String) -> void:
	_NewAsset.thumbnail = thumb
	_NewAsset.text = text

# Adds adds to the 'Existing assets' list
func add_asset(id : int, thumb : Texture, text : String) -> void:
	var tmp := CARD.instance()
	_Cards.add_child(tmp)
	tmp.id = id
	tmp.thumbnail = thumb
	tmp.text = text
	tmp.connect("selected", self, "_card_selected", [tmp])

func _clear() -> void:
	for c in _Cards.get_children():
		c.queue_free()

func _card_selected(card) -> void:
	if _SelectedCard:
		_SelectedCard.selected = false
	
	_SelectedCard = card
	_OverwriteBtn.disabled = false

func _on_New_pressed():
	emit_signal("create_new_asset")
	_on_Cancel_pressed()

func _on_Cancel_pressed():
	# Cleanup
	_SelectedCard = null
	_OverwriteBtn.disabled = true
	_clear()
	
	hide()

func _on_Overwrite_pressed():
	emit_signal("overwrite", _SelectedCard.id)
	_on_Cancel_pressed()
