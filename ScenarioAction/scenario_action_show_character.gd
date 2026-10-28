extends ScenarioAction
class_name ScenarioActionShowCharacter

@export var node_paths: Array[NodePath] = [^"."]
@export var wait_for_animation: bool = true

func _run(host: Node) -> void:
	for node in node_paths:
		if is_instance_valid(node):
			host.get_node(node).showCharacter()
			await host.get_tree().create_timer(randf_range(0.15, 0.3)).timeout
		else:
			continue
	await host.get_tree().create_timer(randf_range(0.15, 0.3)).timeout
	return
