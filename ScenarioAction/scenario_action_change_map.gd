
extends ScenarioAction
class_name ScenarioActionChangeMap

@export_file("*.tscn") var map_scene_path: String = ""
@export var spawn: String = "default"
@export var change_scenario: bool = false
@export var new_scenario: int = 0


func _run(host: Node) -> void:
	if map_scene_path == "":
		return
	var new_map := load(map_scene_path).instantiate() as MapScene
	if new_map == null:
		push_warning("[ScenarioAction] ChangeMap: %s is not a MapScene." % map_scene_path)
		return
	if change_scenario:
		PlayerState.scenario = new_scenario
		
	await CommonFunctions._change_map_scene(map_scene_path, spawn)
