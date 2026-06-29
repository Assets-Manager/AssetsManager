extends PanelContainer

signal changed()

@onready var chips : Chips = $Chips
@export var readonly = false

func _on_chips_request_options(text: String) -> void:
	var authors = AssetsLibrary.search_authors(text)
	var options : Array[Autocomplete.Option] = []
	for author in authors:
		var option = Autocomplete.Option.new()
		option.display_text = author.name
		option.value = author
		options.push_back(option)
	
	chips.options = options

func _on_chips_chip_added(chip: Chip) -> void:
	if chip.value == null:
		if readonly:
			chip.queue_free()
		else:
			chip.value = AssetsLibrary.add_author(chip.text)
	changed.emit()

func _on_chips_chip_removed(_chip: Chip) -> void:
	changed.emit()
