extends ScenarioAction
class_name ScenarioActionHideCharacter

@export var node_path: NodePath = ^"."
@export var await_character_spin: bool = false
## Wait for the ~1.5s hide tween before the next action runs.
@export var wait_for_animation: bool = true


func _run(host: Node) -> void:
	var target := host.get_node_or_null(node_path)
	if target == null or not (target is Interactible):
		push_warning("[ScenarioAction] HideCharacter: target is not an Interactible.")
		return
	if wait_for_animation:
		await target.hideCharacter(await_character_spin)
	else:
		target.hideCharacter(await_character_spin)
