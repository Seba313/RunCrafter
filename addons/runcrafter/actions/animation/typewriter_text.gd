@tool
class_name RCTypewriterText
extends RCAction

const CATEGORY := "Animation"
const DESCRIPTION := "Reveals the text of a Label / RichTextLabel letter by letter. Optionally an input action shows everything at once."

@export var target: NodePath
## New text (use {variable}). Empty = keep the current text.
@export_multiline var text: String = ""
@export var characters_per_second: float = 30.0
## Pressing this action shows the whole text immediately.
@export var skip_input_action: String = ""
@export var finish_event: String = ""

var _shown: float = 0.0
var _total: int = 0


func _on_enter() -> void:
	var n := get_target()
	if not (n is Label or n is RichTextLabel):
		push_warning("RunCrafter Typewriter Text: target must be a Label or RichTextLabel.")
		finish()
		return
	if not text.is_empty():
		n.text = format_text(text)
	_total = n.get_total_character_count() if n is RichTextLabel else n.text.length()
	_shown = 0.0
	n.visible_characters = 0


func _on_update(delta: float) -> void:
	var n := get_target()
	if n == null:
		finish()
		return
	_shown += characters_per_second * delta
	if not skip_input_action.is_empty() and InputMap.has_action(skip_input_action) and Input.is_action_just_pressed(skip_input_action):
		_shown = _total
	n.visible_characters = mini(int(_shown), _total)
	if int(_shown) >= _total:
		n.visible_characters = -1
		finish()
		send_event(finish_event)
