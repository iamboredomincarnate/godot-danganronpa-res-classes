
extends ScenarioAction
class_name ScenarioActionReplaceNode

## The node currently in the scene that should be replaced.
@export var target_path: NodePath
## The node (typically under this branch) to put in its place.
@export var replacement_path: NodePath
@export var keep_groups: bool = false


func _run(host: Node) -> void:
	var target := host.get_node_or_null(target_path)
	var replacement := host.get_node_or_null(replacement_path)
	if target == null or replacement == null:
		push_warning("[ScenarioAction] ReplaceNode: target or replacement missing.")
		return
	target.replace_by(replacement, keep_groups)
