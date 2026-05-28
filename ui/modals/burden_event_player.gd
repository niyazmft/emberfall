extends Control

## BurdenEventPlayer
## UI component that plays out the Burden Event sequence.

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _current_result: BurdenManager.BurdenEventResult


func _ready() -> void:
	if BurdenManager:
		BurdenManager.burden_event_triggered.connect(_on_burden_event_triggered)


func _on_burden_event_triggered(result: BurdenManager.BurdenEventResult) -> void:
	_current_result = result
	_play_sequence()


func _play_sequence() -> void:
	## Phase A starts immediately.
	## Per DON-222: Phase A caption fires at the exact moment the Burden Event seizes control.
	## (Scheduling is handled by BurdenManager.trigger_burden_event)

	## Logic for other phases (B, C, D) would go here,
	## likely driven by an AnimationPlayer or a state machine.
	if anim_player:
		anim_player.play("burden_event_sequence")
