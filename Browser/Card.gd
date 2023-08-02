extends MarginContainer

onready var _Texture := $Card/MarginContainer/VBoxContainer/TextureRect
onready var _Title := $Card/MarginContainer/VBoxContainer/Title

func set_texture(texture : Texture) -> void:
	_Texture.texture = texture

func set_title(title : String) -> void:
	_Title.text = title
