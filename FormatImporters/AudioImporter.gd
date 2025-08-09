extends IFormatImporter

# Returns the name of the type e.g.: Image
static func get_type() -> String:
	return "Audio"
	
# Returns a list of supported file extensions.
static func get_extensions() -> Array:
	return [
		"wav",
		"mp3",
		"flac",
		"ogg"
	]

func render_thumbnail(path: String) -> Texture2D:
	var audio_renderer : GDAudioWaveRenderer = GDAudioWaveRenderer.new()
	return audio_renderer.render_audio_wave(path, Vector2(128, 128))
