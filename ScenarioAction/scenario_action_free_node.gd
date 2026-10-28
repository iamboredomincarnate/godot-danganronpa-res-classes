extends ScenarioAction
class_name ScenarioActionFreeNode

@export var node_path: NodePath = ^"."
@export var immediate: bool = false


func _run(host: Node) -> void:
	var target := host.get_node_or_null(node_path)
	if target == null:
		return
		
	if target is Interactible: target.remove_from_group("Interactible")
	if immediate:
		target.free()
	else:
		target.queue_free()
