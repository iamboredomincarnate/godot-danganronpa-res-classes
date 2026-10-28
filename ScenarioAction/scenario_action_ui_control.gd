@tool
extends ScenarioAction
class_name ScenarioAction_UI_Control

enum UI_CONTROL {
	SLIDE_OUT,
	SLIDE_IN,
	FADE_OUT,
	FADE_IN,
	
	DISPLAY_CG,
	NONE,
	DISABLE_PLAYER_INPUT,
	ENABLE_PLAYER_INPUT,
	BLOCK_EXIT,
	ALLOW_EXIT
}

@export var ui_ctrl : UI_CONTROL:
	set(value):
		ui_ctrl = value
		notify_property_list_changed()
		
@export var hold_after : float

@export var CG_PATH : Resource

func _validate_property(property: Dictionary) -> void:
	if property.name == "CG_PATH" and ui_ctrl != UI_CONTROL.DISPLAY_CG:
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _run(_host: Node) -> void:
	
	match ui_ctrl:
		
		UI_CONTROL.SLIDE_OUT:
			
			UiElements.slide_ui(false)
			
		UI_CONTROL.SLIDE_IN:
			
			UiElements.slide_ui(true)
			
		UI_CONTROL.FADE_OUT:
			
			UiElements.UI_CG_HANDLER.display_black_screen()
		
		UI_CONTROL.FADE_IN:
			
			UiElements.UI_CG_HANDLER.clear_all_cgs()
			
		UI_CONTROL.DISPLAY_CG:
			
			UiElements.UI_CG_HANDLER.display_new_cg(CG_PATH)
			
		UI_CONTROL.DISABLE_PLAYER_INPUT:
			
			PlayerState.ALLOW_OVERWORLD_MOVEMENT=false
			
		UI_CONTROL.ENABLE_PLAYER_INPUT:
			
			PlayerState.ALLOW_OVERWORLD_MOVEMENT=true
			
		UI_CONTROL.BLOCK_EXIT:
			
			PlayerState.BLOCK_ROOM_EXIT=true
			
		UI_CONTROL.ALLOW_EXIT:
			PlayerState.BLOCK_ROOM_EXIT=false

	await _host.get_tree().create_timer(hold_after).timeout
			
	return
