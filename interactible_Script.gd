@tool
@icon("res://ASSETS/2D/Menus/person.svg")
extends Node3D
class_name Interactible

enum INTERACTIBLE_TYPES { CHARACTER_SINGULAR, CHARACTER_TREE, WARP }
enum HITBOX_TYPE        { SPRITE, COLLISIONSHAPE, PREEXISTING_OBJECT }
enum SPAWN_MODE { ALWAYS, REQUIRE_SET, REQUIRE_UNSET }

signal Interaction_Over

const PREVIEW_CROP_SIZE     := Vector2i(500, 500)
const EDITOR_PREVIEW_Y_OFFSET := 1.1
const SILHOUETTE_GROW_AMOUNT  := -0.04
const baseTextbox = preload("res://Scenes/UserInterface/Textbox/BaseTextbox.tscn")
const proper_pixel_size := 0.005

var HasIndicator : bool = false

@export var interactType: INTERACTIBLE_TYPES:
	set(value):
		interactType = value
		notify_property_list_changed()
	
@export var collideType: HITBOX_TYPE
@export var VisualName: String

## SPAWN MODE / SPAWN FLAG
## Controls what scenarios need to be met for this interactible to appear.
## ALWAYS 		- Self Explanatory.
## REQUIRE_SET	- spawn_flag must be found and true in PlayerState.SaveFile
## REQUIRE_UNSET- spawn_flag must be either unfound or false in PlayerState.SaveFile
@export var spawn_mode: SPAWN_MODE = SPAWN_MODE.ALWAYS
@export var spawn_flag: String = ""

## INTERACTION SYSTEM
## 
## on_interaction_before:
## Runs when the character is selected via ui_confirm before the textbox event happens
## on_interaction_over:
## Runs when the character's textbox is over. This does not await so player control
## is returned as this happens. Set PlayerState.AllowPlayerMovement to false 
## if on_interaction_over needs to be awaited 

@export var on_interaction_before: Array[ScenarioAction]
@export var on_interaction_over: Array[ScenarioAction]

## Does this need to be reusable? (reactions_once will disconnect on_interaction_over)
@export var reactions_once: bool = false

## What sprite data are we using for this character?
## Only important for Character/Sprite-based Interactibles.
@export var characterData: CharacterData
@export var spriteIndex := 0:
	set(value):
		spriteIndex = value
		_updateCharacterSprite()

## Controls what preview is being shown in the editor
@export var sprite_preview: Texture2D:
	set(value):
		sprite_preview = value

## Provide a nodepath to substitute the hitbox of ourselves with the
## hitbox of another node in the scene
@export var TargetObject_Path: NodePath

## What textbox will be used when this character is talked to?
@export var TEXTBOX: TextboxArrayData

## If this is a warp, where are we doing? (uid of map from dir)
@export var Warpto: String
## What spawn are we going to? (Defaults to "DEFAULT" if nothing is provided)
@export var Warpto_Warp: String


## Export Tool for editor which allows us to toggle if we have the Indicator
## Node for this character visible.
@export_tool_button("Toggle Indicator") var c = Callable(self, "_toggle_indicator")

func _toggle_indicator() -> void:
	var existing := get_node_or_null("Indicator")
	if existing == null:
		var n := Indicator.new()
		n.name = "Indicator"
		add_child(n, true)
		n.owner = get_tree().edited_scene_root
	else:
		existing.queue_free()
	

## In relation to this object, where are the other objects in the scene?
## (We care about this for our dynamic camera movement in the Textbox)
@export var CharacterOrigins : Dictionary[TextboxArrayData.CH_LIST, NodePath] = {}

## Where is the current camera in the SceneTree?
@export var CurrentCamera : NodePath

## Do we automatically set what the offsets are when we interact with
## this node for the first time, or are baked in Editor?
@export var SetCharacterCamera_OnInteractionStart: bool = false

## Tool button to update the Character Offsets in our Textbox metadata
## Requires Textbox and Camera be set properly
@export_tool_button("Automatically Set Character Offsets") var d = Callable(self, "_handle_offsets")
func _handle_offsets():
	
	if (not TEXTBOX): 
		push_error("[%s]: Assign a Textbox first." % name)
		return
	
	if (not CurrentCamera):
		push_warning("[%s]: Assign a Camera first." % name)
	
	var camerap = get_node(CurrentCamera).global_position
	
	for ch in CharacterOrigins.keys():
		
		var s = CharacterOrigins[ch] as NodePath
		var dif
		
		if s.get_name(0).begins_with("ScenarioFile"):
			dif = get_parent().get_node(CharacterOrigins[ch].slice(1)).global_position - camerap
		else:
			dif = get_node(CharacterOrigins[ch]).global_position - camerap
			
		#CommonFunctions._pass_message(self, str(dif), CommonFunctions.msg_types.LOG)
			
		dif.y = 0
		TEXTBOX.character_offsets[ch] = dif
	
## How much detail do we need in the inspector?
## (If Verbose is set to true, we get more information)
@export var Verbose: bool = false:
	set(value):
		Verbose = value
		notify_property_list_changed()
		
## What properties need to be visible to the user based on the 
## current Interactible Type?
func _validate_property(property: Dictionary) -> void:
	match property.name:
		"characterData", "spriteIndex", "sprite_preview":
			if (interactType == INTERACTIBLE_TYPES.CHARACTER_SINGULAR) and (collideType == HITBOX_TYPE.SPRITE):
				pass
			else:
				property.usage &= ~PROPERTY_USAGE_EDITOR
				
		"Warpto", "Warpto_Warp":
			if interactType != INTERACTIBLE_TYPES.WARP:
				property.usage &= ~PROPERTY_USAGE_EDITOR
		"TEXTBOX":
			if interactType != INTERACTIBLE_TYPES.CHARACTER_SINGULAR:
				property.usage &= ~PROPERTY_USAGE_EDITOR
				
		"TargetObject_Path":
			if not (collideType == HITBOX_TYPE.PREEXISTING_OBJECT):
				property.usage &= ~PROPERTY_USAGE_EDITOR
				
	match property.name:
		"spawn_mode", "spawn_flag", "reactions_once","on_interaction_before", "on_interaction_over", "auto_translate_mode", "script","physics_interpolation_mode", "process_thread_group", "editor_description":
			if not Verbose:
				property.usage &= ~PROPERTY_USAGE_EDITOR
				
		"rotation_edit_mode", "rotation_order", "top_level", "visibility_parent", "process_mode", "process_priority","process_physics_priority", "rotation", "scale":
			if not Verbose:
				property.usage &= ~PROPERTY_USAGE_EDITOR
						
		

## Tool Button to automatically create an Area3D+Shape. 
## Useful for objects, but Sprite-based interactibles 
## create this automatically.
@export_tool_button("Create CollisionArea") var _create_collision_area : Callable = func():
	if get_node_or_null("Area3D"): return
	var _new_area3d = Area3D.new(); _new_area3d.name = "Area3D"
	self.add_child(_new_area3d, true); _new_area3d.owner = get_tree().edited_scene_root
	
	var _new_collision_shape = CollisionShape3D.new();
	var _new_shape = SphereShape3D.new();
	_new_shape.radius = 1.0 
	_new_collision_shape.shape = _new_shape
	get_node("Area3D").add_child(_new_collision_shape)
	_new_area3d.owner = get_tree().edited_scene_root
	return
	
var area:     StaticBody3D
var hitbox:   CollisionShape3D
var editor_preview_sprite: Sprite3D
var silhouette_sprite:     Sprite3D
var isHandlingInput := false

## Checks the save file to make sure we're meant to spawn this.
func _passes_spawn_condition() -> bool:
	match spawn_mode:
		SPAWN_MODE.REQUIRE_SET:
			return PlayerState.CheckSaveCondition(spawn_flag)
		SPAWN_MODE.REQUIRE_UNSET:
			return not PlayerState.CheckSaveCondition(spawn_flag)
		_:
			return true

func _ready() -> void:
	## Are we in the editor? If not, then check if this needs to be shown
	if not Engine.is_editor_hint(): 
		if not _passes_spawn_condition():
			queue_free()
			return
		_cleanup_editor_preview()

	## Make sure this is in the Interactible group so we can interact with it
	add_to_group("Interactible", true)

	var sprite := _get_or_create_sprite()
	_apply_sprite_settings(sprite)
	_setup_hitbox()
	_updateCharacterSprite()
	
	# DEPRECATED #
	# _AfterInteraction can be extended to run custom code
	# if needed, but it doesn't integrate with the rest of the
	# codebase anymore
	# kept as legacy feature, but ScenarioAction.run_method does this better
	Interaction_Over.connect(_AfterInteraction)

	if not Engine.is_editor_hint() and not on_interaction_over.is_empty():
		Interaction_Over.connect(_run_interaction_reactions)

func _run_interaction_reactions() -> void:
	if reactions_once and Interaction_Over.is_connected(_run_interaction_reactions):
		Interaction_Over.disconnect(_run_interaction_reactions)
	await ScenarioAction.run_sequence(on_interaction_over, self)

func _get_or_create_sprite() -> Sprite3D:
	if has_node("Sprite3D"):
		return $Sprite3D
	var sprite := Sprite3D.new()
	sprite.name   = "Sprite3D"
	sprite.shaded = true
	add_child(sprite, true)
	return sprite

## Assign the proper perameters to our Sprite3D when initalized
func _apply_sprite_settings(sprite: Sprite3D) -> void:

	sprite.pixel_size = proper_pixel_size / 10.0
	sprite.billboard  = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED  
	sprite.alpha_scissor_threshold = 0.02

	if silhouette_sprite and is_instance_valid(silhouette_sprite):
		silhouette_sprite.pixel_size = sprite.pixel_size
		
func _updateCharacterSprite() -> void:
	if not characterData:
		return
	if spriteIndex < 0 or spriteIndex >= characterData.spriteSet.size():
		return

	var source_tex: Texture2D = characterData.spriteSet[spriteIndex]
	if not source_tex:
		return

	var sprite := _get_or_create_sprite()
	_apply_sprite_settings(sprite)
	sprite.texture = source_tex

	var sil := _get_or_create_silhouette(sprite)
	sil.texture     = source_tex
	sil.pixel_size  = sprite.pixel_size
	sil.billboard   = BaseMaterial3D.BILLBOARD_FIXED_Y
	sil.flip_h      = sprite.flip_h
	if sil.material_override is StandardMaterial3D:
		sil.material_override.albedo_texture = source_tex

	var tex_size := source_tex.get_size()
	var crop_w   := int(min(PREVIEW_CROP_SIZE.x, tex_size.x))
	var crop_h   := int(min(PREVIEW_CROP_SIZE.y, tex_size.y))

	var preview      := AtlasTexture.new()
	preview.atlas    = source_tex
	preview.region   = Rect2i(int((tex_size.x - crop_w) * 0.5), 0, crop_w, crop_h)
	sprite_preview   = preview

	if Engine.is_editor_hint():
		var prev := _get_or_create_editor_preview()
		prev.texture                    = sprite_preview
		prev.pixel_size                 = sprite.pixel_size
		prev.visibility_range_begin     = 7.0
		prev.visibility_range_begin_margin = 1
		prev.no_depth_test              = true
		prev.billboard                  = BaseMaterial3D.BILLBOARD_ENABLED
		prev.fixed_size                 = true
		prev.position                   = Vector3(0, tex_size.y * sprite.pixel_size * EDITOR_PREVIEW_Y_OFFSET, 0)
	else:
		_cleanup_editor_preview()


func _get_or_create_silhouette(source_sprite: Sprite3D) -> Sprite3D:
	if silhouette_sprite and is_instance_valid(silhouette_sprite):
		return silhouette_sprite

	silhouette_sprite              = Sprite3D.new()
	silhouette_sprite.name         = "SilhouetteSprite3D"
	silhouette_sprite.shaded       = false
	silhouette_sprite.no_depth_test = false
	silhouette_sprite.billboard    = BaseMaterial3D.BILLBOARD_FIXED_Y
	silhouette_sprite.pixel_size   = source_sprite.pixel_size
	silhouette_sprite.modulate     = Color.BLACK
	silhouette_sprite.sorting_offset = -1.0
	silhouette_sprite.position     = Vector3.ZERO
	silhouette_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	

	var mat                  := StandardMaterial3D.new()
	mat.shading_mode          = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color          = Color.BLACK
	mat.transparency          = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode 		  = source_sprite.billboard
	mat.albedo_texture        = source_sprite.texture
	mat.grow                  = true
	mat.grow_amount           = SILHOUETTE_GROW_AMOUNT
	silhouette_sprite.material_override = mat

	add_child(silhouette_sprite, true)
	move_child(silhouette_sprite, 0)
	return silhouette_sprite

func _update_sillouette_billboard(source_sprite : Sprite3D):
	silhouette_sprite.mat.billboard_mode=source_sprite.billboard
	
func _setup_hitbox() -> void:
	area = get_node_or_null("StaticBody3D")
	if area == null:
		area      = StaticBody3D.new()
		area.name = "StaticBody3D"
		add_child(area, true)

	hitbox = area.get_node_or_null("CollisionShape3D")
	if hitbox == null:
		hitbox      = CollisionShape3D.new()
		hitbox.name = "CollisionShape3D"
		area.add_child(hitbox, true)

	match collideType:
		HITBOX_TYPE.SPRITE:           _update_sprite_hitbox()
		HITBOX_TYPE.PREEXISTING_OBJECT: _update_preexisting_hitbox()

func _update_preexisting_hitbox() -> void:
	var target_node = get_node_or_null(TargetObject_Path)
	if not target_node or not target_node is VisualInstance3D:
		push_error("Preexisting object not found or is not a VisualInstance3D.")
		return

	var aabb     = target_node.get_aabb()
	var box_size  = aabb.size * target_node.scale

	var box       := BoxShape3D.new()
	box.size       = box_size
	hitbox.shape   = box
	hitbox.position = target_node.position + (aabb.get_center() * target_node.scale)

func _update_sprite_hitbox() -> void:
	if not has_node("Sprite3D"):
		return
	var sprite: Sprite3D = $Sprite3D
	if not sprite.texture:
		return

	var tex_size := sprite.texture.get_size()
	var ps       := sprite.pixel_size

	var box      := BoxShape3D.new()
	box.size      = Vector3(tex_size.x * ps, tex_size.y * ps, tex_size.x * ps)
	hitbox.shape  = box
	hitbox.position = Vector3.ZERO

	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS


## Disable the Interactible's hitbox until the function returns
func DisableInput(TimeUntilRestart: float) -> void:
	hitbox.disabled = true
	await get_tree().create_timer(TimeUntilRestart).timeout
	hitbox.disabled = false

## We click on it. What happens?
func HandleInput(playerCamera: Camera3D, awaitSignal: bool = false) -> void:
	# If we shouldn't be accepting input, return early.
	if isHandlingInput or PlayerState.INTERACTION_IN_PROGRESS:
		return

	@warning_ignore("redundant_await")
	await _BeforeInteraction() # DEPRECATED - Use on_interaction_before.run_method
	
	isHandlingInput                    = true 
	PlayerState.INTERACTION_IN_PROGRESS = true
	
	UiElements.UI_CURSOR.pause_update  = true
	UiElements.UI_CURSOR.path_anm_node.play("ZOOM")
	
	if (SetCharacterCamera_OnInteractionStart):
		if (CurrentCamera): _handle_offsets()

	if collideType == HITBOX_TYPE.COLLISIONSHAPE:
		await get_tree().create_timer(1.0).timeout

	await _handle_interaction(playerCamera, awaitSignal)

	PlayerState.INTERACTION_IN_PROGRESS = false
	UiElements.UI_CURSOR.pause_update   = false
	isHandlingInput                     = false
	UiElements.current_hover_text       = ""
	PlayerState.current_interactible	= null


func _handle_interaction(playerCamera: Camera3D, awaitSignal: bool = false) -> void:
	
	await ScenarioAction.run_sequence(on_interaction_before, self)
	
	match interactType:
		INTERACTIBLE_TYPES.CHARACTER_SINGULAR:
			await _handle_character_singular(playerCamera, awaitSignal)
		INTERACTIBLE_TYPES.WARP:
			await _handle_warp(playerCamera)
	Interaction_Over.emit()

@warning_ignore("unused_parameter")
func _handle_character_singular(playerCamera: Camera3D, awaitSignal: bool = false) -> void:
	if collideType == HITBOX_TYPE.SPRITE and (characterData):
		await hideCharacter(awaitSignal)
	elif hitbox:
		hitbox.disabled = true

	if TEXTBOX != null:
		var newTextbox               = baseTextbox.duplicate().instantiate()
		newTextbox.textboxGroup      = TEXTBOX.textboxGroup
		newTextbox.textboxMetadata   = { "Offsets": TEXTBOX.character_offsets }
		get_tree().root.add_child(newTextbox)
		await newTextbox.endingTextbox

	if collideType == HITBOX_TYPE.SPRITE:
		await showCharacter()
	elif hitbox:
		hitbox.disabled = false

func _handle_warp(playerCamera: Camera3D) -> void:
	await ZoomCamera_smooth(64.3, 50.0, 0.25, playerCamera)
	CommonFunctions._change_map_scene(Warpto, Warpto_Warp)
	
func _set_sprite_billboard(mode: BaseMaterial3D.BillboardMode) -> void:
	$Sprite3D.billboard = mode
	if silhouette_sprite and is_instance_valid(silhouette_sprite):
		silhouette_sprite.billboard = mode
		
func hideCharacter(awaitCharacterSpin: bool = false) -> void:
	if awaitCharacterSpin:
		await UiElements.StartCharacterSpin

	if not collideType == HITBOX_TYPE.SPRITE:
		push_error("Trying to hide a sprite, but hitbox is a StaticBody3D.")
		return

	_set_sprite_billboard(BaseMaterial3D.BILLBOARD_DISABLED)
	if silhouette_sprite and is_instance_valid(silhouette_sprite):
		silhouette_sprite.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED

	$Sprite3D.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED

	var target_angle := face_node(PlayerState.CharacterCamera)
	$Sprite3D.rotation.y = target_angle

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite3D, "rotation", Vector3(0, target_angle + deg_to_rad(-720), 0), 1.5)
	tween.tween_property($Sprite3D, "modulate", Color(1, 1, 1, 0), 1.5)

	if silhouette_sprite and is_instance_valid(silhouette_sprite):
		tween.tween_property(silhouette_sprite, "rotation", Vector3(0, target_angle + deg_to_rad(-720), 0), 1.5)
		tween.tween_property(silhouette_sprite.material_override, "albedo_color", Color(0, 0, 0, 0), 1.5)

	await tween.finished
	visible = false
	
# TODO: replace get_angle_to_face calls with added 4.3 native function
func get_angle_to_face(from_pos: Vector3, target_pos: Vector3) -> float:
	var direction: Vector3 = target_pos - from_pos
	var angle: float = atan2(direction.x, direction.z)
	return angle
	
## TODO: replace face_node calls with added 4.3 native function
func face_node(target: Node3D) -> float:
	if not self: return 0
	if not target: return 0
	var target_angle: float = get_angle_to_face(global_position, target.global_position)
	return target_angle
	
func showCharacter() -> void:
	if not collideType == HITBOX_TYPE.SPRITE:
		push_error("Trying to show a sprite, but hitbox is a StaticBody3D.")
		return

	var target_angle := face_node(PlayerState.CharacterCamera)

	$Sprite3D.rotation.y = target_angle + deg_to_rad(720)
	$Sprite3D.modulate.a = 0.0
	$Sprite3D.alpha_cut  = SpriteBase3D.ALPHA_CUT_DISABLED

	_set_sprite_billboard(BaseMaterial3D.BILLBOARD_DISABLED)

	if silhouette_sprite and is_instance_valid(silhouette_sprite):
		silhouette_sprite.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		silhouette_sprite.rotation.y = target_angle + deg_to_rad(720)
		silhouette_sprite.material_override.albedo_color = Color(0, 0, 0, 0)

	visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Sprite3D, "rotation", Vector3(0.0, target_angle, 0.0), 1.5)
	tween.tween_property($Sprite3D, "modulate", Color(1, 1, 1, 1), 1.5)

	if silhouette_sprite and is_instance_valid(silhouette_sprite):
		tween.tween_property(silhouette_sprite, "rotation", Vector3(0.0, target_angle, 0.0), 1.5)
		tween.tween_property(silhouette_sprite.material_override, "albedo_color", Color(0, 0, 0, 1), 1.5)

	await tween.finished

	$Sprite3D.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	if silhouette_sprite:
		silhouette_sprite.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	_set_sprite_billboard(BaseMaterial3D.BILLBOARD_FIXED_Y)
	visible = true
	

func ZoomCamera_smooth(from: float, to: float, time: float, cam: Camera3D) -> void:
	var fovTween := create_tween()
	fovTween.set_ease(Tween.EASE_IN_OUT)
	fovTween.set_trans(Tween.TRANS_QUAD)
	cam.fov = from
	fovTween.tween_property(cam, "fov", to, time)
	await fovTween.finished

func _get_or_create_editor_preview() -> Sprite3D:
	if editor_preview_sprite and is_instance_valid(editor_preview_sprite):
		return editor_preview_sprite

	editor_preview_sprite           = Sprite3D.new()
	editor_preview_sprite.name      = "EditorSpritePreview"
	editor_preview_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	editor_preview_sprite.shaded    = false
	editor_preview_sprite.visible   = true
	add_child(editor_preview_sprite, true)
	return editor_preview_sprite

func _cleanup_editor_preview() -> void:
	if editor_preview_sprite and is_instance_valid(editor_preview_sprite):
		editor_preview_sprite.queue_free()
		editor_preview_sprite = null

func _AfterInteraction() -> void:
	pass

func _BeforeInteraction() -> void:
	return
