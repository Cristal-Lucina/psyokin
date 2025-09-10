# res://scripts/integrations/OpenAIClient.gd
# -----------------------------------------------------------------------------
# OpenAI REST client for Godot 4.x (GDScript, typed, no emojis, tabs).
# - Uses HTTPRequest (single instance) for simple, non-streaming calls.
# - Reads API key from ENV (OPENAI_API_KEY) or user://secrets.cfg.
# - Exposes chat() that hits Chat Completions; also parses "Responses" shape.
# - Returns clean text and never throws on parse errors (logs instead).
# -----------------------------------------------------------------------------

extends Node
class_name OpenAIClient

signal chat_done(ok: bool, text: String)

const API_HOST: String = "https://api.openai.com"
const CHAT_PATH: String = "/v1/chat/completions"  # classic endpoint
const RESP_PATH: String = "/v1/responses"         # newer Responses API (optional)

# Default model; change to what your account supports.
const DEFAULT_MODEL: String = "gpt-4o-mini"

var _http: HTTPRequest
var _in_flight: bool = false

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func _exit_tree() -> void:
	cancel()

# --- Public API ---------------------------------------------------------------

## Aborts any in-flight HTTP request.
func cancel() -> void:
	_http.cancel_request()
	_in_flight = false

## Simple chat request. Emits chat_done(ok, text).
func chat(prompt: String, system_prompt: String = "You are a helpful game dev assistant.") -> void:
	if _in_flight:
		push_warning("OpenAIClient: request already in flight; ignoring.")
		return

	var key: String = _get_api_key()
	if key.is_empty():
		push_error("OpenAIClient: missing API key. Set OPENAI_API_KEY or user://secrets.cfg.")
		emit_signal("chat_done", false, "")
		return

	var headers: PackedStringArray = PackedStringArray([
		"Authorization: Bearer %s" % key,
		"Content-Type: application/json"
	])

	# Chat Completions body (easy to parse)
	var body: Dictionary = {
		"model": DEFAULT_MODEL,
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": prompt}
		],
		"temperature": 0.2
	}

	# If you prefer the new "Responses" API, switch to:
	# var body: Dictionary = {
	# 	"model": DEFAULT_MODEL,
	# 	"input": prompt
	# }
	# and replace CHAT_PATH with RESP_PATH below.

	var err: int = _http.request(API_HOST + CHAT_PATH, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		push_error("OpenAIClient: HTTP request error = %s" % err)
		emit_signal("chat_done", false, "")
		return

	_in_flight = true

# --- Secrets ------------------------------------------------------------------

## Reads key from ENV or user://secrets.cfg:
##   [openai]
##   api_key="sk-..."
func _get_api_key() -> String:
	var key: String = OS.get_environment("OPENAI_API_KEY")
	if not key.is_empty():
		return key

	var cfg := ConfigFile.new()
	if cfg.load("user://secrets.cfg") == OK:
		key = String(cfg.get_value("openai", "api_key", ""))
	return key

# --- HTTP callback ------------------------------------------------------------

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_in_flight = false

	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("OpenAIClient: transport error %d" % result)
		emit_signal("chat_done", false, "")
		return

	var text: String = body.get_string_from_utf8()
	if response_code != 200:
		push_error("OpenAIClient: HTTP %d -> %s" % [response_code, text])
		emit_signal("chat_done", false, "")
		return

	var json := JSON.new()
	var parse_ok: int = json.parse(text)
	if parse_ok != OK:
		push_error("OpenAIClient: JSON parse error %d" % parse_ok)
		emit_signal("chat_done", false, "")
		return

	var data: Variant = json.data
	var answer: String = _extract_text(data)
	emit_signal("chat_done", true, answer)

# Extracts assistant text from both Chat Completions and Responses shapes.
func _extract_text(data: Variant) -> String:
	# Defensive checks with explicit local typings to keep warnings quiet.
	if typeof(data) != TYPE_DICTIONARY:
		return ""

	var dict: Dictionary = data

	# Chat Completions: { choices: [ { message: { content: "..." } } ] }
	if dict.has("choices"):
		var choices_any: Variant = dict["choices"]
		if typeof(choices_any) == TYPE_ARRAY:
			var choices: Array = choices_any
			if choices.size() > 0:
				var first_choice: Variant = choices[0]
				if typeof(first_choice) == TYPE_DICTIONARY:
					var choice_dict: Dictionary = first_choice
					var msg_any: Variant = choice_dict.get("message")
					if typeof(msg_any) == TYPE_DICTIONARY:
						var msg: Dictionary = msg_any
						if msg.has("content"):
							return String(msg["content"])

	# Responses API:
	# { output: [ { content: [ { type:"output_text", text:"..." }, ... ] }, ... ] }
	if dict.has("output"):
		var out_any: Variant = dict["output"]
		if typeof(out_any) == TYPE_ARRAY:
			var out: Array = out_any
			if out.size() > 0:
				var first_out: Variant = out[0]
				if typeof(first_out) == TYPE_DICTIONARY:
					var out_dict: Dictionary = first_out
					var content_any: Variant = out_dict.get("content")
					if typeof(content_any) == TYPE_ARRAY:
						var content: Array = content_any
						for block_any in content:
							if typeof(block_any) == TYPE_DICTIONARY:
								var block: Dictionary = block_any
								# Prefer explicit "text" field if present.
								if block.has("text"):
									return String(block["text"])
								# Some variants store text under nested keys; add guards here if needed.

	# Fallback: nothing found
	return ""
