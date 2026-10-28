extends ScenarioAction
class_name ScenarioActionSongFade
@export var fade_duration : float = 2.5

func _run(_host: Node) -> void:
	UiElements.fade_song(fade_duration)
	pass
