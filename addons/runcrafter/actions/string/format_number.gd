@tool
class_name RCFormatNumber
extends RCAction

const CATEGORY := "String"
const DESCRIPTION := "Formats a number as text (decimals, leading zeros, thousands separator, prefix/suffix)."

@export var number: float = 0.0
@export var decimals: int = 0
## Minimum number of integer digits (e.g. 3 -> 007).
@export var min_digits: int = 1
@export var thousands_separator: String = ""
@export var prefix: String = ""
@export var suffix: String = ""
@export var store_result: String = ""
@export var every_frame: bool = false


func _on_enter() -> void:
	if not every_frame:
		finish()
	_do()


func _on_update(_delta: float) -> void:
	_do()


func _do() -> void:
	var neg := number < 0.0
	var txt := String.num(absf(number), decimals) if decimals > 0 else str(int(round(absf(number))))
	if decimals > 0 and not txt.contains("."):
		txt += "." + "0".repeat(decimals)
	var int_part := txt.get_slice(".", 0)
	var frac := txt.substr(int_part.length())
	if decimals > 0 and frac.length() < decimals + 1:
		frac += "0".repeat(decimals + 1 - frac.length())
	int_part = int_part.lpad(min_digits, "0")
	if not thousands_separator.is_empty():
		var out := ""
		var c := 0
		for i in range(int_part.length() - 1, -1, -1):
			out = int_part[i] + out
			c += 1
			if c % 3 == 0 and i > 0:
				out = thousands_separator + out
		int_part = out
	store(store_result, prefix + ("-" if neg else "") + int_part + frac + suffix)
