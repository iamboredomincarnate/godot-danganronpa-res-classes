## Sets the time of day. `time_name` matches a key of UiElements.Times
## (e.g. "Afternoon"), so it stays readable in the inspector.
extends ScenarioAction
class_name ScenarioActionSetTime

@export var time_name: String = ""


func _run(_host: Node) -> void:
	if time_name == "":
		return
	if time_name in UiElements.Times:
		UiElements.slide_ui(false)
		await _host.get_tree().create_timer(1.5).timeout
		UiElements.CurrentTime = UiElements.Times[time_name]
		UiElements.slide_ui(true)
	else:
		push_warning("[ScenarioAction] Unknown time of day: %s" % time_name)
