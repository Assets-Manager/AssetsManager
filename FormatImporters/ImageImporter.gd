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

func render_thumbnail(path: String) -> Texture2D:
	var img : Image = Image.new()
	var result : ImageTexture = null
	if img.load(path) == OK:
		# Any image which is larger than the thumbnail size, will be scaled down.
		if (img.get_width() > 128) || (img.get_height() > 128):
			var aspect : float = float(img.get_width()) / float(img.get_height())
			if img.get_width() > img.get_height():
				var width : int = 128
				img.resize(width, round(width / aspect))
			else:
				var height : int = 128
				img.resize(round(height * aspect), height)
				
		result = ImageTexture.create_from_image(img)
	
	return result
