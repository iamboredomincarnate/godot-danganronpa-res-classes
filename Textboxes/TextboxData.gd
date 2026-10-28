@tool
extends Resource
class_name TextboxData


## The list of possible character names for a textbox.
##
## Special ones include none, which means there's no name
##		associated with this text, and unknown, which is '???'.
##	The rest display the character's full name after processing the data.

var ticker_max := 0

const characterDataList = {} ## NAME enum asoc w/ CharacterData preload

const characterNameList = {
	NAMES.unknown: "???"
}

enum NAMES {
	none,
	unknown,
	}
enum TEXTBOX_TYPES {
	
	STANDARD, # Normal textbox
	CHOICE, # Branches per player input
	ANIMATION, # Plays an animation 
	FUNCTION, # Runs a method
	JUMP, # Jumps to a different textbox
	COMMENT, ## I love comments
	BRANCH, ## Branches to a different textbox based on PlayerState.SaveData indice
	EVENT ## Runs a TextboxEvent

}

enum TEXTBOX_ANIMATIONS {
	none,
	
	flashLight,
	flashHeavy,
	shakeLight,
	shakeHeavy 
	
}

@export_category("Basic")

## The chosen character name. Who's currently speaking? List below...
@export var characterName : NAMES:
	set(value):
		characterName = value
		currentCharacter = characterDataList.get(characterName, null)
		displayName = str(characterNameList.get(characterName, null))
		_update_character_sprite()

@export var spriteIndex := 0:
	set(value):
		if value<0: value = 0
		if currentCharacter:
			spriteIndex = clamp(value, 0, currentCharacter.spriteSet.size() - 1)
		else:
			spriteIndex = 0
		_update_character_sprite()

@export var current_TextboxEvent : TextboxEvent
		
func _update_character_sprite() -> void:
	if currentCharacter == null:
		characterSprite = null
		characterPreview = null
		ticker_max = 0
		return

	if spriteIndex < 0 or spriteIndex >= currentCharacter.spriteSet.size():
		characterSprite = null
		characterPreview = null
		ticker_max = 0
		return

	characterSprite = currentCharacter.spriteSet[spriteIndex]
	_update_sprite_preview()

	# --- Set ticker max based on the sprite index / available sprites ---
	ticker_max = currentCharacter.spriteSet.size()



func _update_sprite_preview() -> void:
	if characterSprite == null:
		characterPreview = null
		return

	var atlas_size := characterSprite.get_size()

	if atlas_size.x < 500 or atlas_size.y < 500:
		characterPreview = null
		return

	var region_x := int((atlas_size.x - 500) * 0.5)
	var region_y := 0

	var atlas := AtlasTexture.new()
	atlas.atlas = characterSprite
	atlas.region = Rect2i(region_x, region_y, 500, 500)

	characterPreview = atlas
	
	return


var currentCharacter : CharacterData
var characterSprite : Texture2D
@export var characterPreview : Texture2D


@export var displayName : String
## Multipurpose textBlock. It's use depends on the TextboxType.
## Standard : The dialogue being spoken.
## Choice : The choice options
## Animation : The name of the animation to be played.
## Function: The name of the function to be called.
@export_multiline var textBlock: String:
	set(value):
		textBlock = value
		if not (textboxType == TEXTBOX_TYPES.CHOICE): return
		var lines = str(textBlock).split("\n", false)
		
		# Remove keys from Choices that no longer exist in the new textBlock
		# We use .keys() to get a static list so we can safely erase during the loop
		for existing_key in Choices.keys():
			if not existing_key in lines:
				Choices.erase(existing_key)
		
		# Add new lines as keys if they aren't already there
		for line in lines:
			if not Choices.has(line):
				Choices[line] = TextboxArrayData.new()
			elif Choices[line] is not TextboxArrayData: 
				Choices[line] = TextboxArrayData.new()
		

## This controls wether a character is 'thinking' or not. 
## Thinking text has a leading and an ending bracket, and is
##		 [color=blue]blue[/color] in color.
@export var TextboxStyle : TextStyles = TextStyles.Standard

enum TextStyles {
	Standard,
	Thinking,
	Green
}

@export_group("Advanced")

@export_range(0.2, 1.0, 0.01, "suffix: cps") var textSpeed 

@export var Voiceline : AudioStream

@export var KeepPreviousSprite : bool = false

@export var textboxType: TEXTBOX_TYPES = TEXTBOX_TYPES.STANDARD

@export var textboxAnimation: String

@export var Choices = {}
@export var CustomScript := ""
