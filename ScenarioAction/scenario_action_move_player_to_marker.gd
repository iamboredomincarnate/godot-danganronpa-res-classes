extends ScenarioAction
class_name ScenarioActionMovePlayerToMarker

@export var marker_path: NodePath
@export var keep_player_height: bool = true
@export var set_facing: bool = true
@export var face_angle_degrees: float = 0.0

enum MOVEMENT { LEAVE_AS_IS, BLOCK, UNBLOCK }
@export var overworld_movement: MOVEMENT = MOVEMENT.LEAVE_AS_IS


func _run(host: Node) -> void:
	var map := PlayerState.CurrentMap
	if map == null:
		return
	var player := map.get_node_or_null(map.PLAYER_NODE)
	var marker := host.get_node_or_null(marker_path)
	if player == null or marker == null:
		push_warning("[ScenarioAction] MovePlayerToMarker: player or marker missing.")
		return

	var dest: Vector3 = marker.global_position
	if keep_player_height:
		dest.y = player.global_position.y
	player.global_position = dest

	if set_facing:
		player.rotation.y = deg_to_rad(face_angle_degrees)

	match overworld_movement:
		MOVEMENT.BLOCK:
			PlayerState.ALLOW_OVERWORLD_MOVEMENT = false
		MOVEMENT.UNBLOCK:
			PlayerState.ALLOW_OVERWORLD_MOVEMENT = true
