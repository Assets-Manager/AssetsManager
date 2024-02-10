extends WindowDialog

signal overwrite()

onready var _Items := $MarginContainer/VBoxContainer/ItemList

func _ready():
	_Items.add_item("")
	_Items.add_item("")
#	_Items.set_item_disabled(0, true)
#	_Items.set_item_disabled(1, true)

func set_first_element(icon : Texture, title: String) -> void:
	_Items.set_item_icon(0, icon)
	_Items.set_item_text(0, title)

func set_second_element(icon : Texture, title: String) -> void:
	_Items.set_item_icon(1, icon)
	_Items.set_item_text(1, title)

func _on_Button_pressed():
	emit_signal("overwrite")
	hide()

func _on_Button2_pressed():
	hide()
