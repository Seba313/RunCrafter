@tool
class_name RCSetLocale
extends RCAction

const CATEGORY := "Localization"
const DESCRIPTION := "Changes the game language (TranslationServer.set_locale), e.g. 'en', 'pl'."

@export var locale: String = "en"


func _on_enter() -> void:
	finish()
	TranslationServer.set_locale(locale)
