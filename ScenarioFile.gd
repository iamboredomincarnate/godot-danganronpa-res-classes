@tool
@icon("res://ASSETS/2D/Menus/bookmark.svg")
extends Node
class_name ScenarioFile

const PREVIEW_META := &"_scenario_preview_hidden"

# Do the characters in our scene play their show animation
# When they're loaded?
@export var ShowCharacter_OnStart: bool = true

# Load the CGHandler for quick reference
@onready var CGHandler = null if Engine.is_editor_hint() else UiElements.UI_CG_HANDLER

# What scenario does this show in?
@export var ShowUnderScenario := 0:
	set(value):
		ShowUnderScenario = value
		name = "ScenarioFile_" + str(value)

# This is largely a editor feature as hiding/showing
# doesn't play the proper animation
@export var ShowChildren : bool = true:
	set(value):
		ShowChildren = value
		for node in get_children():

			if node is CanvasItem or node is Node3D:
				node.visible = value

# What textboxes will be used?
# This is uneeded unless you care for organization
@export var Textboxes : Array[TextboxArrayData]

# Series of ScenarioActions that will occur on map loaded
@export var OnReady : Array[ScenarioAction]

## True when this branch failed the scenario check and is being discarded.
var _pruned := false

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return

	if PlayerState.scenario != ShowUnderScenario:
		_pruned = true

		for child in get_children():
			remove_child(child)
			child.queue_free()
		queue_free()


func _ready() -> void:
	
	if Engine.is_editor_hint():
		return
	if _pruned:
		return 

	_restore_preview_visibility()

	if ShowCharacter_OnStart:
		show_children()

	_scenario_ready.call_deferred()

func _scenario_ready() -> void:
	await ScenarioAction.run_sequence(OnReady, self)
	_really_ready()
	
# LEGACY FEATURE
# _really_ready() only executes if pruned is false, as it occurs
# after the standard _ready() function. 
# Same idea, but better, can be achieved by using 
# ScenarioAction.run_method in OnReady
func _really_ready() -> void:
	pass

func set_editor_preview(should_show: bool) -> void:
	if not Engine.is_editor_hint():
		return
	for child in get_children():
		if not (child is CanvasItem or child is Node3D):
			continue
		if should_show:
			if child.get_meta(PREVIEW_META, false):
				child.visible = true
				child.remove_meta(PREVIEW_META)
		else:
			if child.visible:
				child.set_meta(PREVIEW_META, true)
				child.visible = false


func _restore_preview_visibility() -> void:
	for child in get_children():
		if child.has_meta(PREVIEW_META):
			if child is CanvasItem or child is Node3D:
				child.visible = true
			child.remove_meta(PREVIEW_META)

# HELPERS #
# Helpers for ScenarioAction
# Most of these are either DEPRECATED or 
# are used directly by ScenarioActions
func pause_for(pause_time: float):
	await get_tree().create_timer(pause_time).timeout
	return

func PlaySong(songPath: String):
	UiElements.play_song_from_path(songPath)
	return

func CheckSave(condition: String) -> bool:
	return PlayerState.CheckSaveCondition(condition)

func SetSave(condition: String, val := true):
	PlayerState.SaveFile[condition] = val
	return

func hide_children(child_list := get_all_children(), time_between = randf_range(0.15, 0.3), time_after = randf_range(0.15, 0.3)):
	for node in child_list:
		node.hideCharacter()
		await pause_for(time_between)
	await pause_for(time_after)
	return

func show_children(child_list := get_all_children(), time_between = randf_range(0.15, 0.3), time_after = randf_range(0.15, 0.3)):
	for node in child_list:
		if is_instance_valid(node):
			node.showCharacter()
			await pause_for(time_between)
		else:
			continue
	await pause_for(time_after)
	return

func get_all_children() -> Array[Interactible]:
	var curArray : Array[Interactible] = []
	for node in get_children():
		if node is Interactible:
			curArray.append(node)
	return curArray as Array[Interactible]

func ShowTextbox(tb: TextboxArrayData) -> void:
	await CommonFunctions.ShowTextbox(tb)
	return

## Eases the current node to a target node's position and Y-rotation
func ease_to_target(move_node: Node3D, target_node: Node3D, duration: float):
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(move_node, "global_position", target_node.global_position, duration)
	tween.tween_method(
		func(val): move_node.global_rotation.y = val,
		move_node.global_rotation.y,
		target_node.global_rotation.y,
		duration
	)

func PlaySFX(sfx: String):
	var NewAudioPlayer = AudioStreamPlayer.new()
	NewAudioPlayer.stream = load(sfx)
	NewAudioPlayer.finished.connect(NewAudioPlayer.queue_free)
	add_child(NewAudioPlayer)
	NewAudioPlayer.play()
	return

func PushCG(cg: String, wait_after := 0.0):
	var texture = ImageTexture.create_from_image(Image.load_from_file(cg))
	UiElements.UI_CG_HANDLER.display_new_cg(texture)
	await pause_for(wait_after)
	return

# Display a textbox only if it hasn't been seen before.
# sfi functions as the save file indice, and if it
# returns false (doesn't exist in the save file or is false)
# we show the textbox, and after toggle it to true
func ShowUnseen_Textbox(tb: TextboxArrayData, sfi: String):
	if CheckSave(sfi):
		return
	await ShowTextbox(tb)
	SetSave(sfi, true)
	return

# What properties are available in the inspector?
# (ScenarioFile doesn't need positions so we prune anything from Node) 
func _validate_property(property: Dictionary) -> void:
	# Get all property names from Node
	var node3d_props = []
	for p in Node.new().get_property_list():
		node3d_props.append(p.name)

	# If this property exists in Node3D, remove its editor usage
	if property.name in node3d_props:
		property.usage &= ~PROPERTY_USAGE_EDITOR
