@tool
extends Resource
class_name TextboxArrayData

static var DIALOGUE_LIST : Dictionary[String, Array] = {}
@export_group("Textbox")
@export var textboxGroup: Array[TextboxData]

@export_group("Metadata")
enum UITYPES { NORMAL, PLAIN }
@export var UiType: UITYPES

const path_to_textbox_scene = "res://Scenes/UserInterface/Textbox/BaseTextbox.tscn"

enum CH_LIST {} # List of character names

static var StandardChOffsets : Dictionary[CH_LIST, float] = {} ## Vertical camera offset for each enum

@export var character_offsets: Dictionary[CH_LIST, Vector3]

@export var selected_character: CH_LIST = CH_LIST.AKAGI
@export var selected_offset: Vector3 = Vector3.ZERO

@export var apply_character_offset := false:
	set(value):
		apply_character_offset = false
		_set_character_offset(selected_character, selected_offset)
		_notify_editor_changed()

func get_character_offset(ch: CH_LIST) -> Vector3:
	var offset: Vector3 = character_offsets.get(ch, Vector3.ZERO)
	if StandardChOffsets.has(ch):
		offset.y = StandardChOffsets[ch]
	return offset

func set_character_offset(ch: CH_LIST, offset: Vector3) -> void:
	if StandardChOffsets.has(ch):
		offset.y = StandardChOffsets[ch]
	character_offsets[ch] = offset

func clear_character_offset(ch: CH_LIST) -> void:
	if character_offsets.has(ch):
		character_offsets.erase(ch)

func has_character_offset(ch: CH_LIST) -> bool:
	return character_offsets.has(ch)


func _set_character_offset(ch: CH_LIST, offset: Vector3) -> void:
	set_character_offset(ch, offset)

func _notify_editor_changed() -> void:
	if Engine.is_editor_hint():
		notify_property_list_changed()

func setup_dialogue_list() -> void:
	var a = []
	for t in textboxGroup:
		if t and t.textBlock:
			a.append(t.textBlock)
	if not resource_name.is_empty():
		DIALOGUE_LIST[resource_name] = a
