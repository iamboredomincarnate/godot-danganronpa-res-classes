extends Resource
class_name ScenarioAction

enum GATE { NONE, REQUIRE_SET, REQUIRE_UNSET }

@export var gate: GATE = GATE.NONE:
	set(value):
		gate = value
		notify_property_list_changed()
		
@export var gate_flag: String = ""

func _validate_property(property: Dictionary) -> void:
	
	match property.name:
	
		"gate_flag":
			if (gate == GATE.NONE):
				property.usage &= ~PROPERTY_USAGE_EDITOR

static func run_sequence(actions: Array, host: Node) -> void:
	for action in actions:
		if action is ScenarioAction:
			await action.execute(host)

func execute(host: Node) -> void:
	if not _passes_gate():
		return
	PlayerState.ALLOW_OVERWORLD_MOVEMENT=false
	@warning_ignore("redundant_await")
	await _run(host)
	PlayerState.ALLOW_OVERWORLD_MOVEMENT=true

func _passes_gate() -> bool:
	match gate:
		GATE.REQUIRE_SET:
			return PlayerState.CheckSaveCondition(gate_flag)
		GATE.REQUIRE_UNSET:
			return not PlayerState.CheckSaveCondition(gate_flag)
		_:
			return true

func _run(_host: Node) -> void:
	pass
