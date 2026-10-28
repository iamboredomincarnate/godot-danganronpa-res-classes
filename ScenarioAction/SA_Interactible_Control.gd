extends ScenarioAction
class_name SA_Interactible_Control

@export_multiline var note: String = "SA_Interactible_Control can only be used under Interactible events.\nChanges Metadata for the current interactible."

enum OPTIONS {
	GIVE_INDICATOR,
	REMOVE_INDICATOR,
	
	CHANGE_TEXTBOX,		## Adds Textbox Var
	CHANGE_NAME,			## Adds Name Var
	CHANGE_TYPE
}

@export var InteractibleOptions : OPTIONS:
	set(value):
		InteractibleOptions=value
		emit_changed()
		
@export var NewTextbox: TextboxArrayData
@export var newName: String

func _validate_property(property: Dictionary) -> void:
	
	if property.name == "NewTextbox": 
		if (InteractibleOptions == OPTIONS.CHANGE_TEXTBOX):
			property.usage &= ~PROPERTY_USAGE_EDITOR
		
	if property.name == "newName": 
		if (InteractibleOptions == OPTIONS.CHANGE_NAME):
			property.usage &= ~PROPERTY_USAGE_EDITOR

func _run(_host: Node) -> void:
	
	if not (_host is Interactible):
		push_error("SA_Interactible_Control is only usable when atatched to a Interactible.")
		
	_host = _host as Interactible
	
	match InteractibleOptions:
		
		OPTIONS.CHANGE_NAME:
			_host.VisualName = newName
			
		OPTIONS.CHANGE_TEXTBOX:
			_host.TEXTBOX = NewTextbox
			
		
