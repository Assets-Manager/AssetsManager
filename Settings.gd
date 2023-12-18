class_name Settings
extends Resource

enum TutorialStep {
	LIBRARY_SCREEN = 1,
	BROWSER_SCREEN = 2
}

export var recent_asset_libraries : Array = []
export var last_opened : String = ""
export var disclaimer_accepted : bool = false
export var tutorial_step : int = 0
