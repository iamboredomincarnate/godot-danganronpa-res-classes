## Plays an animation on a AnimationPlayer in the SceneTree
extends ScenarioAction
class_name ScenarioActionPlayAnimation

@export var animation_player_path: NodePath
@export var animation_name: String = ""
## If true, the sequence waits for the animation to finish before continuing.
@export var wait_for_finish: bool = false


func _run(host: Node) -> void:
	var ap := host.get_node_or_null(animation_player_path) as AnimationPlayer
	if ap == null:
		push_warning("[ScenarioAction] AnimationPlayer not found at: %s" % animation_player_path)
		return
	ap.play(animation_name)
	if wait_for_finish:
		await ap.animation_finished
