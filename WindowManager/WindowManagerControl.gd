extends TabContainer

func _ready():
	WindowManager.connect("switch_view", self, "_switch_view")
	WindowManager.connect("switch_home", self, "_switch_home")
	
	var viewers = WindowManager.get_viewers()
	for viewer in viewers:
		add_child(viewer)
		
func _switch_view(viewer : IViewer) -> void:
	var index = get_children().find(viewer)
	if index != -1:
		current_tab = index

func _switch_home() -> void:
	current_tab = 0
