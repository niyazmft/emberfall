extends Node

## ToastManager
## Queues and displays toast notifications.

enum ToastType {
	T_01, ## INFO
	T_02, ## SUCCESS
	T_03, ## WARNING
	T_04, ## ERROR
	T_05  ## SYSTEM
}

const TOAST_SCENE = preload("res://scenes/ui/toast.tscn")
const DISMISS_TIME = 3.0

var _queue: Array[Dictionary] = []
var _is_displaying: bool = false

func _ready() -> void:
	LayerManager.modal_opened.connect(_on_modal_opened)
	LayerManager.modal_closed.connect(_on_modal_closed)

func show_toast(text_key: String, type: ToastType = ToastType.T_01) -> void:
	_queue.append({"key": text_key, "type": type})
	_process_queue()

func _process_queue() -> void:
	if _is_displaying or _queue.is_empty() or LayerManager.is_modal_active():
		return

	_is_displaying = true
	var data = _queue.pop_front()
	var toast = TOAST_SCENE.instantiate()
	LayerManager.add_child(toast)
	toast.display(data.key, data.type, DISMISS_TIME)
	toast.finished.connect(_on_toast_finished)

func _on_toast_finished() -> void:
	_is_displaying = false
	_process_queue()

func _on_modal_opened() -> void:
	# Toast queue is paused by LayerManager check in _process_queue
	pass

func _on_modal_closed() -> void:
	_process_queue()
