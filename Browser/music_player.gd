extends MarginContainer

@onready var _Playbar := $VBoxContainer/Playbar
@onready var _MusicPlayer := $MusicPlayer
@onready var _CurrentTime := $VBoxContainer/HBoxContainer/CurrentTime
@onready var _TotalTime := $VBoxContainer/HBoxContainer/TotalTime

var _stop_updating = false

func set_audio_asset(asset: AMAsset) -> void:
	var strm = GDAudioStream.new()	
	if strm.load(AssetsLibrary.generate_and_migrate_assets_path(AssetsLibrary.get_asset_real_filename(asset), asset.id)) == OK:
		_stop_updating = false
		_Playbar.value = 0
		_MusicPlayer.stream = strm
		_Playbar.max_value = strm.get_length()
		_TotalTime.text = _format_time(strm.get_length())
		_MusicPlayer.play()
		show()

func _process(_delta: float) -> void:
	if _MusicPlayer.playing && !_stop_updating:
		_Playbar.value = floor(_MusicPlayer.get_playback_position())
		_CurrentTime.text = _format_time(_Playbar.value)
	elif !_MusicPlayer.playing && !_stop_updating:
		hide()

func _format_time(time: float) -> String:
	var minutes : int = floor(time / 60)
	var hours : int = floor(minutes / 60.0)
	minutes -= hours * 60
	var seconds : int = floor(time - minutes * 60)
	
	var result = ""
	if hours:
		result = "%02d:" % hours
		
	result += "%02d:%02d" % [minutes, seconds]
	return result

func _on_playbar_drag_started() -> void:
	_stop_updating = true

func _on_playbar_drag_ended(value_changed: bool) -> void:
	_MusicPlayer.stop()
	_MusicPlayer.play(_Playbar.value)
	_stop_updating = false

func _on_play_pressed() -> void:
	_MusicPlayer.stop()
	_MusicPlayer.stream = null
	hide()
