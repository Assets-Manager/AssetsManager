extends VBoxContainer

const CARD = preload("res://Browser/Card.tscn")
const ITEMS_PER_PAGE : int = 100

onready var _Cards := $ScrollContainer/CenterContainer/Cards
onready var _ImporterDialog := $CanvasLayer/ImporterDialog
onready var _Pagination := $Pagination
onready var _Search := $MarginContainer/HBoxContainer/Search

func _ready() -> void:
	if AssetsLibrary.open("c:/AssetsTest"):
		AssetsLibrary.connect("update_total_import_assets", self, "_update_total_import_assets")
		AssetsLibrary.connect("new_asset_added", self, "_new_asset_added")
		
		_Pagination.total_pages = ceil(AssetsLibrary.get_assets_count(0, "") / float(ITEMS_PER_PAGE))

func _update_total_import_assets(total_files : int) -> void:
	_ImporterDialog.set_total_files(total_files)
	if _ImporterDialog.visible:
		_ImporterDialog.set_value(0)
		_ImporterDialog.visible = true

func _new_asset_added(name : String, thumbnail : Texture) -> void:
	if _Cards.get_child_count() < ITEMS_PER_PAGE:
		var tmp := CARD.instance()
		_Cards.add_child(tmp)
		tmp.set_texture(thumbnail)
		tmp.set_title(name)
		_ImporterDialog.increment_value()
	
	if _ImporterDialog.get_value() == _ImporterDialog.get_total_files():
		_ImporterDialog.hide()

func _on_Pagination_page_update(page : int) -> void:
	if _Cards:
		var cards := AssetsLibrary.query_assets(0, _Search.text, (page - 1) * ITEMS_PER_PAGE, ITEMS_PER_PAGE)
		for child in _Cards.get_children():
			child.hide()
		
		var count = 0
		for card in cards:
			var tmp
			
			# Creates or reuses a card element.
			if count >= _Cards.get_child_count():
				tmp = CARD.instance()
				_Cards.add_child(tmp)
			else:
				tmp = _Cards.get_child(count)
				tmp.visible = true
				
			count += 1
			
			tmp.set_meta("id", card["id"])
			
			if card.has("thumbnail"):
				tmp.set_texture(card["thumbnail"])
				
			tmp.set_title(card["name"])

func _on_Search_text_entered(_new_text: String) -> void:
	_Pagination.set_total_pages_without_update(ceil(AssetsLibrary.get_assets_count(0, _Search.text) / float(ITEMS_PER_PAGE)))
	_Pagination.current_page = 1
