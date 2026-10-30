@tool
class_name RCHttpRequest
extends RCAction

const CATEGORY := "Network"
const DESCRIPTION := "Sends an HTTP request and stores the response (optionally parsed JSON). Use {variable} in URL and body."
const TITLE := "HTTP Request"

@export var url: String = "https://"
@export_enum("GET", "POST", "PUT", "DELETE") var method: int = 0
## One header per line, e.g. "Content-Type: application/json"
@export var headers: PackedStringArray = PackedStringArray()
@export_multiline var body: String = ""
@export var parse_json: bool = true
@export var timeout: float = 10.0
@export var store_response: String = ""
@export var store_status_code: String = ""
@export var success_event: String = ""
@export var failed_event: String = ""

var _http: HTTPRequest

const METHODS := [HTTPClient.METHOD_GET, HTTPClient.METHOD_POST, HTTPClient.METHOD_PUT, HTTPClient.METHOD_DELETE]


func _on_enter() -> void:
	_http = HTTPRequest.new()
	_http.timeout = timeout
	fsm.add_child(_http)
	_http.request_completed.connect(_on_completed)
	var err := _http.request(format_text(url), headers, METHODS[method], format_text(body))
	if err != OK:
		_cleanup()
		finish()
		send_event(failed_event)


func _on_completed(result: int, code: int, _headers: PackedStringArray, data: PackedByteArray) -> void:
	_cleanup()
	finish()
	var text := data.get_string_from_utf8()
	store(store_status_code, code)
	if result != HTTPRequest.RESULT_SUCCESS or code >= 400:
		store(store_response, text)
		send_event(failed_event)
		return
	var value: Variant = text
	if parse_json:
		var parsed: Variant = JSON.parse_string(text)
		if parsed != null:
			value = parsed
	store(store_response, value)
	send_event(success_event)


func _on_exit() -> void:
	_cleanup()


func _cleanup() -> void:
	if is_instance_valid(_http):
		_http.cancel_request()
		_http.queue_free()
	_http = null
