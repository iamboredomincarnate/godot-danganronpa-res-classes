extends ScenarioAction
class_name ScenarioActionChangeScenario

@export var new_scenario : int

func _run(_host: Node) -> void:
	PlayerState.scenario=new_scenario
	return
