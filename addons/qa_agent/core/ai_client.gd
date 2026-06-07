class_name QAAIClient
extends RefCounted
## HTTP client for cloud Vision-Language-Action APIs.
## Currently targets the OpenAI chat.completions endpoint with vision support.
## Compatible with any API that implements the same JSON schema (e.g., local proxies,
## Azure OpenAI, etc.).
##
## Usage:
##   var client := QAAIClient.new("https://api.openai.com/v1", "sk-...")
##   var response: Dictionary = await client.sendVisionPrompt(base64_png, "What do you see?", "png")

const DEFAULT_TIMEOUT_SEC: float = 60.0
const DEFAULT_MAX_TOKENS: int = 1024

## Base URL without trailing slash, e.g. "https://api.openai.com/v1"
var apiBase: String = ""

## Bearer token or API key.
var apiKey: String = ""

## Model identifier, e.g. "gpt-4o", "gpt-4o-mini".
var model: String = "gpt-4o"

## Maximum tokens in the response.
var maxTokens: int = DEFAULT_MAX_TOKENS

## HTTP request timeout in seconds.
var timeoutSec: float = DEFAULT_TIMEOUT_SEC

var _http: HTTPRequest = null
var _pending: bool = false


func _init(pApiBase: String, pApiKey: String) -> void:
	apiBase = pApiBase.rstrip("/")
	apiKey = pApiKey


## Sends a vision prompt with a base64-encoded image and returns the parsed
## JSON response as a Dictionary. Must be called with `await`.
## On failure, returns {"error": String}.
## `format` should match the image encoding used ("png" or "jpeg").
func sendVisionPrompt(image_base64: String, prompt_text: String, format: String = "png") -> Dictionary:
	var body: Dictionary = {
		"model": model,
		"max_tokens": maxTokens,
		"messages": [
			{
				"role": "user",
				"content": [
					{"type": "text", "text": prompt_text},
					{
						"type": "image_url",
						"image_url": {
							"url": "data:image/" + format + ";base64," + image_base64
						}
					}
				]
			}
		]
	}
	return await _performRequest(body)


## Sends a text-only prompt. Useful for follow-up questions without re-sending images.
func sendTextPrompt(prompt_text: String) -> Dictionary:
	var body: Dictionary = {
		"model": model,
		"max_tokens": maxTokens,
		"messages": [
			{"role": "user", "content": prompt_text}
		]
	}
	return await _performRequest(body)


## Extract the assistant message content from a successful response.
static func extractContent(response: Dictionary) -> String:
	if response.has("choices") and response["choices"] is Array:
		var choices: Array = response["choices"] as Array
		if choices.size() > 0:
			var first: Dictionary = choices[0] as Dictionary
			if first.has("message") and first["message"] is Dictionary:
				var msg: Dictionary = first["message"] as Dictionary
				return str(msg.get("content", ""))
	return ""


func _performRequest(body: Dictionary, endpoint: String = "/chat/completions") -> Dictionary:
	if _pending:
		return {"error": "Request already in flight"}
	_pending = true

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		_pending = false
		return {"error": "No active SceneTree"}

	_http = HTTPRequest.new()
	_http.timeout = timeoutSec
	tree.root.add_child(_http)

	var url: String = apiBase + endpoint
	var json := JSON.new()
	var body_str: String = json.stringify(body)
	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"Authorization: Bearer " + apiKey
	]

	var err: Error = _http.request(url, headers, HTTPClient.METHOD_POST, body_str)
	if err != OK:
		_cleanup()
		return {"error": "HTTPRequest error: " + str(err)}

	var completed := false
	var result: Array = []

	_http.request_completed.connect(
		func(p_result: int, p_code: int, p_headers: PackedStringArray, p_body: PackedByteArray):
			completed = true
			result = [p_result, p_code, p_headers, p_body]
	)

	var timer: SceneTreeTimer = tree.create_timer(timeoutSec + 5.0)
	await timer.timeout

	if not completed:
		_cleanup()
		return {"error": "HTTP request timed out after " + str(timeoutSec) + "s"}

	_cleanup()

	var http_result: int = result[0] as int
	var response_code: int = result[1] as int
	var body_bytes: PackedByteArray = result[3] as PackedByteArray

	if http_result != HTTPRequest.RESULT_SUCCESS:
		return {"error": "HTTP result code: " + str(http_result)}
	if response_code < 200 or response_code >= 300:
		return {"error": "HTTP " + str(response_code) + ": " + body_bytes.get_string_from_utf8()}

	var parse_err: Error = json.parse(body_bytes.get_string_from_utf8())
	if parse_err != OK:
		return {"error": "JSON parse error: " + str(parse_err)}

	var data: Dictionary = json.data as Dictionary
	if data.has("error"):
		return {"error": str(data["error"])}

	return data


func _cleanup() -> void:
	_pending = false
	if _http != null:
		_http.queue_free()
		_http = null
