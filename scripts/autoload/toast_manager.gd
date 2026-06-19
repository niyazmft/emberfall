class_name _ToastManager
extends Node

## ToastManager
## Queues and displays toast notifications.

enum ToastType { T_01 = 1, T_02 = 2, T_03 = 3, T_04 = 4, T_05 = 5 }  ## INFO  ## SUCCESS  ## WARNING  ## ERROR  ## SYSTEM

const TOAST_SCENE: PackedScene = preload("res://scenes/ui/toast.tscn")
const DISMISS_TIME: float = 3.0

var _queue: Array[Dictionary] = []
var _is_displaying: bool = false


func _ready() -> void:
	var lm: _LayerManager = AutoloadHelper.layer_manager()
	if lm:
		lm.modal_closed.connect(_on_modal_closed)


func _exit_tree() -> void:
	var lm: _LayerManager = AutoloadHelper.layer_manager()
	if lm and lm.modal_closed.is_connected(_on_modal_closed):
		lm.modal_closed.disconnect(_on_modal_closed)


func show_toast(text_key: String, type: ToastType = ToastType.T_01) -> void:
	_queue.append({"key": text_key, "type": type})
	_process_queue()


func _process_queue() -> void:
	var lm: _LayerManager = AutoloadHelper.layer_manager()
	if _is_displaying or _queue.is_empty() or (lm and lm.is_modal_active()):
		return

	_is_displaying = true
	var data: Dictionary = _queue.pop_front() as Dictionary
	var toast := TOAST_SCENE.instantiate() as _ToastWidget
	var lm2: _LayerManager = AutoloadHelper.layer_manager()
	if lm2:
		lm2.add_child(toast)
	if toast:
		toast.display(str(data.get("key", "")), int(data.get("type", 1)), DISMISS_TIME)

	if toast.has_signal("finished"):
		toast.connect("finished", _on_toast_finished)


func _on_toast_finished() -> void:
	_is_displaying = false
	_process_queue()


func _on_modal_closed() -> void:
	_process_queue()
