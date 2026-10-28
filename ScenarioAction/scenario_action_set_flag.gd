## Sets (or clears) a save flag. Replaces SetSave("X") / SetSave("X", false).
extends ScenarioAction
class_name ScenarioActionSetFlag

@export var flag: String = ""
@export var value: bool = true


func _run(_host: Node) -> void:
	if flag != "":
		PlayerState.SaveFile[flag] = value
