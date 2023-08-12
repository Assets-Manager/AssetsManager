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
