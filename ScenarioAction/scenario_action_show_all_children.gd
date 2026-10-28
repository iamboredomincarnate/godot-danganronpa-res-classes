@tool
extends ScenarioAction
class_name SA_ShowAllChildren

@export_multiline var note: String = "SA_ShowAllChildren can only be used under ScenarioFile or CutsceneFile events\nPlays the 'show' animation of all interactibles in the current ScenarioFile."

func _validate_property(property: Dictionary) -> void:
	if property.name == "note":
		property.usage |= PROPERTY_USAGE_READ_ONLY
		
func _run(_host: Node) -> void:
	
	if _host.has_method("show_children"): _host.show_children()
	else: push_warning(_host.name+" does not have associated method.")
	return
