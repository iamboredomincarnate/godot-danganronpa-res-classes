extends ScenarioAction
class_name ScenarioActionMoveCamera

@export var NodeCamera: NodePath
@export var NewPosition: NodePath
@export var MoveDuration: float
@export var awaitMovement: bool = true

func _run(_host: Node) -> void:
	
	var nt = _host.get_tree().create_tween() as Tween
	nt.set_ease(Tween.EASE_IN_OUT)
	nt.set_trans(Tween.TRANS_SINE)
	var nc = _host.get_node_or_null(NodeCamera)
	var np = _host.get_node_or_null(NewPosition)
	
	if (nc):
		
		nt.tween_property(nc, "global_position", np.global_position, MoveDuration)
		if awaitMovement: await nt.finished
		
	return
		
		
