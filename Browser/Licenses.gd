extends PanelContainer

signal changed()

@onready var chips : Chips = $Chips

func _on_chips_request_options(text: String) -> void:
	var licenses = AssetsLibrary.search_licenses(text)
	var options : Array[Autocomplete.Option] = []
	for license in licenses:
		var option = Autocomplete.Option.new()
		option.display_text = license.name
		option.value = license
		options.push_back(option)
	
	chips.options = options

func _on_chips_chip_added(chip: Chip) -> void:
	if chip.value == null:
		chip.queue_free()
		return
	changed.emit()

func _on_chips_chip_removed(_chip: Chip) -> void:
	changed.emit()
