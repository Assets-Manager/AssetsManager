extends IFormatImporter

# Returns the name of the type e.g.: Image
static func get_type() -> String:
	return "Blender"
	
# Returns a list of supported file extensions.
static func get_extensions() -> Array:
	return ["blend"]

# Blender supports thumbnails since 2.50
func _thumbnail_supported(header : String) -> bool:
	var version : int = header.substr(9).to_int()
	return version >= 250
	
func _header_pointer_size(header : String) -> int:
	return 4 if header[7] == '_' else 8

# Extracts the thumbnail from the .blend file
func _extract_thumbnail(file : FileAccess, head_size : int) -> Texture2D:
	var result : ImageTexture = null
	var img : Image = Image.new()
	
	while !file.eof_reached():
		var chunk_header : String = file.get_buffer(4).get_string_from_utf8()
		var size : int = file.get_32()
		file.seek(file.get_position() + (head_size - 8))
		
		if size < 0:
			return null
			
		match chunk_header:
			"TEST":
				var width : int = file.get_32()
				var height : int = file.get_32()
				
				var data_size : int = size - 8
				var expected_data_size : int = width * height * 4
				if (width < 0) || (height < 0) || (data_size != expected_data_size):
					return null
				
				var pixeldata : PackedByteArray = file.get_buffer(data_size)
				img.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixeldata)
				img.flip_y()
				
				result = ImageTexture.create_from_image(img) #,0
				
				return result
				
			"REND":
				file.seek(file.get_position() + size)
				
			_:
				return null
	
	return result

func render_thumbnail(path: String) -> Texture2D:
	var result : ImageTexture = null
	
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		var header : PackedByteArray = file.get_buffer(12)
		if header.size() != 12: # Error no valid super.blend file.
			return null
		
		var header_str : String = header.get_string_from_utf8()
		
		# Currently only uncompressed is supported
		if header_str.begins_with("BLENDER"):
			file.endian_swap = header_str[8] == "V"
			if _thumbnail_supported(header_str):
				var head_size : int = 16 + _header_pointer_size(header_str)
				result = _extract_thumbnail(file, head_size)
	
	return result
