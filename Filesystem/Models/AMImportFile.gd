class_name AMImportFile extends RefCounted

var file : String = ""
var importer: IFormatImporter = null
var status: int = 0
var overwrite_id : int = 0
var parent_id: int = 0

func _init(p_File: String, p_Importer: IFormatImporter, p_Status: int, p_OverwriteId: int, p_ParentId : int = 0) -> void:
	file = p_File
	importer = p_Importer
	status = p_Status
	overwrite_id = p_OverwriteId
	parent_id = p_ParentId
