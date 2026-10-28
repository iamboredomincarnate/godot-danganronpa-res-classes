extends ScenarioAction
class_name ScenarioActionShowTextbox

@export var textbox: TextboxArrayData
@export var only_if_unseen: bool = false
@export var seen_flag: String = ""


func _run(_host: Node) -> void:
	if textbox == null:
		return
	if only_if_unseen and seen_flag != "" and PlayerState.CheckSaveCondition(seen_flag):
		return
	await CommonFunctions.ShowTextbox(textbox)
	if only_if_unseen and seen_flag != "":
		PlayerState.SaveFile[seen_flag] = true
