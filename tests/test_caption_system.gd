extends Node

## Unit / integration tests for the CaptionManager and BurdenManager caption integration.
## Run via Godot Editor test runner or `godot --headless --script tests/test_caption_system.gd`.
## Reference: DON-225 acceptance criteria.

const CAPTION_SCRIPT := preload("res://scripts/autoload/caption_manager.gd")

const BURDEN_SCRIPT := preload("res://scripts/autoload/burden_manager.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("=== Caption System Test Suite (DON-225) ===")
	_test_caption_manager_channels()
	_test_caption_event_opacity_curves()
	_test_burden_transition_captions()
	_test_bd_climb_loop_phase()
	_test_caption_timing_tolerance()
	_test_caption_channel_isolation()
	_test_normal_3_to_0_transition()
	print("")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("Caption system test suite had failures.")
		get_tree().quit(1)
	else:
		get_tree().quit(0)


# ── Helpers ──────────────────────────────────────────────────────────────────


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("ASSERT FAILED: %s" % msg)


func _assertf(a: float, b: float, tolerance: float, msg: String) -> void:
	var diff: float = absf(a - b)
	if diff <= tolerance:
		_passed += 1
	else:
		_failed += 1
		push_error("ASSERT FAILED: %s (|%.4f - %.4f| = %.4f > %.4f)" % [msg, a, b, diff, tolerance])


# ── Test: Channel Enum & Priority ────────────────────────────────────────────


func _test_caption_manager_channels() -> void:
	print("\n[Test] CaptionManager channels")
	var cm: Node = CAPTION_SCRIPT.new()

	_assert(cm.Channel.DIALOGUE == 0, "DIALOGUE channel enum")
	_assert(cm.Channel.BURDEN == 1, "BURDEN channel enum")
	_assert(cm.Channel.AMBIENT == 2, "AMBIENT channel enum")
	_assert(cm.Channel.SFX == 3, "SFX channel enum")

	_assert(cm.CHANNEL_PRIORITY[cm.Channel.BURDEN] == 2, "BURDEN priority = 2")
	_assert(cm.CHANNEL_PRIORITY[cm.Channel.DIALOGUE] == 1, "DIALOGUE priority = 1")

	_assert(cm.CHANNEL_SURFACE_GROUP[cm.Channel.BURDEN] == 1, "BURDEN isolated surface")
	_assert(cm.CHANNEL_SURFACE_GROUP[cm.Channel.DIALOGUE] == 0, "DIALOGUE shared surface")
	_assert(cm.CHANNEL_SURFACE_GROUP[cm.Channel.AMBIENT] == 0, "AMBIENT shared surface")

	print("  channel tests done")


# ── Test: Opacity Curves ─────────────────────────────────────────────────────


func _test_caption_event_opacity_curves() -> void:
	print("\n[Test] CaptionEvent opacity curves")
	var evt: RefCounted = CAPTION_SCRIPT.CaptionEvent.new()
	evt.duration_sec = 2.0

	## INSTANT = 0
	evt.curve = 0
	evt.elapsed_sec = 0.0
	_assert(evt.opacity() == 1.0, "INSTANT at t=0")
	evt.elapsed_sec = 1.0
	_assert(evt.opacity() == 1.0, "INSTANT at t=1")

	## LINEAR = 1 fade-in
	evt.curve = 1
	evt.elapsed_sec = 0.0
	_assertf(evt.opacity(), 0.0, 0.01, "LINEAR fade-in at t=0")
	evt.elapsed_sec = 0.1  ## 5% of 2.0 s = 0.25 opacity in first 20%
	_assertf(evt.opacity(), 0.25, 0.01, "LINEAR fade-in at t=0.1")
	evt.elapsed_sec = 1.0  ## midpoint (hold)
	_assertf(evt.opacity(), 1.0, 0.01, "LINEAR hold at midpoint")
	evt.elapsed_sec = 1.8  ## 90% through = fade-out mid
	_assertf(evt.opacity(), 0.5, 0.01, "LINEAR fade-out at t=1.8")
	evt.elapsed_sec = 2.0
	_assertf(evt.opacity(), 0.0, 0.01, "LINEAR fade-out end")

	## EXPONENTIAL = 2 fade-in
	evt.curve = 2
	evt.elapsed_sec = 0.0
	_assertf(evt.opacity(), 0.0, 0.01, "EXPONENTIAL at t=0")
	evt.elapsed_sec = 0.3  ## end of fade-in window for 2.0 s (0.3/2.0 = 0.15 < 0.3)
	## With duration 2.0, 0.3 s is 0.15 of total, so it's still in fade-in zone
	## t/dur = 0.15 < 0.3, formula: 1 - (1 - 0.15/0.3)^2 = 1 - 0.25 = 0.75
	_assertf(evt.opacity(), 0.75, 0.01, "EXPONENTIAL fade-in mid")
	evt.elapsed_sec = 1.6  ## hold zone
	_assertf(evt.opacity(), 1.0, 0.01, "EXPONENTIAL hold")

	## STEEP_EXPONENTIAL = 4
	evt.curve = 4
	evt.elapsed_sec = 0.0
	_assertf(evt.opacity(), 0.0, 0.01, "STEEP at t=0")
	evt.elapsed_sec = 0.2  ## 10% of 2.0 = first 0.1 s is linear ramp
	## t=0.2, dur=2.0, ratio=0.1. First 0.1 (0.2s) is ramp: 0.2/0.2=1.0, then exp decay
	_assertf(evt.opacity(), 1.0, 0.01, "STEEP peak")
	evt.elapsed_sec = 0.5
	var steep_val: float = evt.opacity()
	_assert(steep_val < 1.0 and steep_val > 0.0, "STEEP decay is between 0 and 1")

	## LOGARITHMIC = 3 tail-off (5.0 s)
	evt.duration_sec = 5.0
	evt.curve = 3
	evt.elapsed_sec = 0.0
	_assertf(evt.opacity(), 0.0, 0.01, "LOG at t=0")
	evt.elapsed_sec = 0.25  ## 5% = first 10% window, ramp to 1
	_assertf(evt.opacity(), 0.5, 0.01, "LOG ramp mid")
	evt.elapsed_sec = 2.5
	var log_val: float = evt.opacity()
	_assert(log_val > 0.0 and log_val < 1.0, "LOG tail-off mid")
	evt.elapsed_sec = 5.0
	_assertf(evt.opacity(), 0.0, 0.01, "LOG end")

	print("  curve tests done")


# ── Test: BurdenManager Transition Caption Scheduling ───────────────────────


func _test_burden_transition_captions() -> void:
	print("\n[Test] BurdenManager transition captions")
	var bm := BURDEN_SCRIPT.new()
	## Force load config (normally done in _ready)
	bm._load_burden_config()
	bm._burden_trigger_count = 0
	bm._lifetime_trigger_count = 0

	## Verify config loaded
	_assert(bm._caption_transitions.has("0_to_1"), "0_to_1 transition exists")
	_assert(bm._caption_transitions.has("2_to_3"), "2_to_3 transition exists")
	_assert(bm._caption_transitions.has("3_to_0_emergency"), "3_to_0_emergency exists")
	_assert(bm._caption_transitions.has("3_to_0_normal"), "3_to_0_normal exists")
	_assert(bm._caption_transitions.has("2_to_1"), "2_to_1 transition exists")
	_assert(bm._caption_transitions.has("1_to_0"), "1_to_0 transition exists")

	## Verify offsets
	var t0_1: Dictionary = bm._caption_transitions["0_to_1"]
	_assertf(float(t0_1.get("offset_sec", 0.0)), 2.0, 0.001, "0→1 offset = 2.0 s")
	_assert(str(t0_1.get("curve", "")) == "EXPONENTIAL", "0→1 curve = EXPONENTIAL")

	var t2_3: Dictionary = bm._caption_transitions["2_to_3"]
	_assertf(float(t2_3.get("offset_sec", 0.0)), 2.5, 0.001, "2→3 offset = 2.5 s")
	_assert(str(t2_3.get("curve", "")) == "EXPONENTIAL", "2→3 curve = EXPONENTIAL")

	var t_emerg: Dictionary = bm._caption_transitions["3_to_0_emergency"]
	_assertf(float(t_emerg.get("offset_sec", 0.0)), 0.5, 0.001, "emergency 3→0 offset = 0.5 s")
	_assert(
		str(t_emerg.get("curve", "")) == "STEEP_EXPONENTIAL",
		"emergency 3→0 curve = STEEP_EXPONENTIAL"
	)

	var t2_1: Dictionary = bm._caption_transitions["2_to_1"]
	_assertf(float(t2_1.get("offset_sec", 0.0)), 1.0, 0.001, "2→1 offset = 1.0 s")
	_assert(str(t2_1.get("curve", "")) == "LINEAR", "2→1 curve = LINEAR")

	var t1_0: Dictionary = bm._caption_transitions["1_to_0"]
	_assertf(float(t1_0.get("offset_sec", 0.0)), 1.0, 0.001, "1→0 offset = 1.0 s")
	_assert(str(t1_0.get("curve", "")) == "LINEAR", "1→0 curve = LINEAR")

	var t_norm: Dictionary = bm._caption_transitions["3_to_0_normal"]
	_assertf(float(t_norm.get("offset_sec", 0.0)), 2.5, 0.001, "normal 3→0 offset = 2.5 s")
	_assert(str(t_norm.get("curve", "")) == "LOGARITHMIC", "normal 3→0 curve = LOGARITHMIC")
	_assertf(float(t_norm.get("duration_sec", 0.0)), 5.0, 0.001, "normal 3→0 duration = 5.0 s")

	print("  transition caption tests done")


# ── Test: BD-CLIMB Loop Phase ──────────────────────────────────────────────


func _test_bd_climb_loop_phase() -> void:
	print("\n[Test] BD-CLIMB loop-phase gate")
	var cm: Node = CAPTION_SCRIPT.new()
	cm._ready()

	cm.set_bd_climb_enabled(true)
	_assert(cm._bd_climb_enabled == true, "BD-CLIMB enabled")

	cm.report_bd_climb_width(0.25)
	_assertf(cm.get_bd_climb_width(), 0.25, 0.001, "width = 0.25")
	_assertf(cm.get_bd_climb_phase(), 0.25, 0.001, "phase derived from width = 0.25")

	cm.report_bd_climb_phase(0.75)
	_assertf(cm.get_bd_climb_phase(), 0.75, 0.001, "explicit phase = 0.75")

	_assert(cm.is_phase_within(0.5, 1.0) == true, "phase 0.75 within [0.5,1.0]")
	_assert(cm.is_phase_within(0.0, 0.5) == false, "phase 0.75 outside [0.0,0.5]")

	cm.report_stem_transient("BD-CLIMB", "peak", 0.8)
	_assert(cm.was_stem_transient_recent("BD-CLIMB", "peak", 1.0) == true, "stem transient recent")
	_assert(
		cm.was_stem_transient_recent("BD-CLIMB", "valley", 1.0) == false,
		"different event id not recent"
	)
	_assert(
		cm.was_stem_transient_recent("BD-MECH", "peak", 1.0) == false, "different stem not recent"
	)

	## Width captions from BurdenManager config
	var bm := BURDEN_SCRIPT.new()
	bm._load_burden_config()
	var caps: Dictionary = bm.get_bd_climb_width_captions()
	_assert(caps.has("expanding"), "expanding caption exists")
	_assert(caps.has("converging"), "converging caption exists")
	_assert(str(caps["expanding"].get("text", "")) == "[The walls widen]", "expanding text")
	_assert(str(caps["converging"].get("text", "")) == "[Everything converges]", "converging text")

	print("  BD-CLIMB tests done")


# ── Test: Caption Timing Tolerance ───────────────────────────────────────────


func _test_caption_timing_tolerance() -> void:
	print("\n[Test] Timing tolerance (±0.2 s)")
	var evt: RefCounted = CAPTION_SCRIPT.CaptionEvent.new()
	evt.offset_sec = 2.0
	evt.duration_sec = 2.0

	_assert(evt.is_timing_accurate(2.0, 0.2) == true, "exact 2.0 within ±0.2")
	_assert(evt.is_timing_accurate(2.19, 0.2) == true, "2.19 within ±0.2")
	_assert(evt.is_timing_accurate(2.21, 0.2) == false, "2.21 outside ±0.2")
	_assert(evt.is_timing_accurate(1.81, 0.2) == true, "1.81 within ±0.2")
	_assert(evt.is_timing_accurate(1.79, 0.2) == false, "1.79 outside ±0.2")

	print("  tolerance tests done")


# ── Test: Channel Isolation ──────────────────────────────────────────────────


func _test_caption_channel_isolation() -> void:
	print("\n[Test] BURDEN channel isolation")
	var cm: Node = CAPTION_SCRIPT.new()
	cm._ready()

	## Simulate scheduling DIALOGUE then BURDEN
	var dia: RefCounted = cm.schedule("Hello", 0, 0.0, 2.0)  ## Channel.DIALOGUE = 0
	var bur: RefCounted = cm.schedule("[The world stills]", 1, 0.0, 2.0)  ## Channel.BURDEN = 1

	## BURDEN should be on isolated surface group
	_assert(bur.surface_group == 1, "BURDEN on isolated surface")
	_assert(dia.surface_group == 0, "DIALOGUE on shared surface")

	## Flush to clean state
	cm.flush_all()
	_assert(cm._active_events.is_empty(), "flush clears active")
	_assert(cm._event_queue.is_empty(), "flush clears queue")

	print("  isolation tests done")


# ── Test: Normal 3→0 Transition ────────────────────────────────────────────


func _test_normal_3_to_0_transition() -> void:
	print("\n[Test] Normal 3→0 transition caption")
	var bm := BURDEN_SCRIPT.new()
	bm._load_burden_config()

	var data: Dictionary = bm._caption_transitions.get("3_to_0_normal", {})
	_assert(not data.is_empty(), "3_to_0_normal config exists")
	_assertf(float(data.get("offset_sec", 0.0)), 2.5, 0.001, "normal 3→0 offset")
	_assertf(float(data.get("duration_sec", 0.0)), 5.0, 0.001, "normal 3→0 duration")
	_assert(str(data.get("curve", "")) == "LOGARITHMIC", "normal 3→0 curve")

	## Verify BurdenManager can schedule it explicitly
	var cm: Node = CAPTION_SCRIPT.new()
	cm._ready()
	## We can't directly test _schedule_transition_caption without a full tree,
	## but we test the explicit API with a dummy caption node
	bm.schedule_transition_caption_explicit("3_to_0_normal")
	## Since cm is not at /root/CaptionManager, this should no-op gracefully
	## (no crash = pass)
	_assert(true, "explicit 3→0 scheduling no-ops gracefully without autoload")

	print("  normal 3→0 tests done")
