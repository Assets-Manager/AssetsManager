extends IFormatImporter

# Returns the name of the type e.g.: Image
static func get_type() -> String:
	return "Image"
	
# Returns a list of supported file extensions.
static func get_extensions() -> Array:
	return [
		"png", 
		"jpg", "jpeg", 
		"bmp", 
		"hdr", 
		"exr", 
		"svg", "svgz",
		"tga", 
		"webp"
	]

func _render_thumbnail(path: String) -> Texture:
	var img : Image = Image.new()
	var result : ImageTexture = null
	if img.load(path):
		# Any image which is larger than the thumbnail size, will be scaled down.
		if (img.get_width() > 128) || (img.get_height() > 128):
			var aspect : float = float(img.get_width()) / float(img.get_height())
			if img.get_width() > img.get_height():
				var width : int = 128
				img.resize(width, round(width / aspect))
			else:
				var height : int = 128
				img.resize(round(height / aspect), height)
				
		result = ImageTexture.new()
		result.create_from_image(img, 0)
	
	return result
