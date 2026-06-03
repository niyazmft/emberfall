extends GdUnitTestSuite

const CAPTION_SCRIPT := preload("res://scripts/autoload/caption_manager.gd")
const BURDEN_SCRIPT := preload("res://scripts/autoload/burden_manager.gd")


func test_caption_manager_channels() -> void:
	var cm: Node = auto_free(CAPTION_SCRIPT.new())

	assert_that(cm.Channel.DIALOGUE).is_equal(0)
	assert_that(cm.Channel.BURDEN).is_equal(1)
	assert_that(cm.Channel.AMBIENT).is_equal(2)
	assert_that(cm.Channel.SFX).is_equal(3)

	assert_that(cm.CHANNEL_PRIORITY[cm.Channel.BURDEN]).is_equal(2)
	assert_that(cm.CHANNEL_PRIORITY[cm.Channel.DIALOGUE]).is_equal(1)

	assert_that(cm.CHANNEL_SURFACE_GROUP[cm.Channel.BURDEN]).is_equal(1)
	assert_that(cm.CHANNEL_SURFACE_GROUP[cm.Channel.DIALOGUE]).is_equal(0)
	assert_that(cm.CHANNEL_SURFACE_GROUP[cm.Channel.AMBIENT]).is_equal(0)


func test_caption_event_opacity_curves() -> void:
	var evt: RefCounted = CAPTION_SCRIPT.CaptionEvent.new()
	evt.duration_sec = 2.0

	evt.curve = 0
	evt.elapsed_sec = 0.0
	assert_that(evt.opacity()).is_equal(1.0)
	evt.elapsed_sec = 1.0
	assert_that(evt.opacity()).is_equal(1.0)

	evt.curve = 1
	evt.elapsed_sec = 0.0
	assert_that(is_equal_approx(evt.opacity(), 0.0)).is_true()
	evt.elapsed_sec = 0.1
	assert_that(is_equal_approx(evt.opacity(), 0.25)).is_true()
	evt.elapsed_sec = 1.0
	assert_that(is_equal_approx(evt.opacity(), 1.0)).is_true()
	evt.elapsed_sec = 1.8
	assert_that(is_equal_approx(evt.opacity(), 0.5)).is_true()
	evt.elapsed_sec = 2.0
	assert_that(is_equal_approx(evt.opacity(), 0.0)).is_true()

	evt.curve = 2
	evt.elapsed_sec = 0.0
	assert_that(is_equal_approx(evt.opacity(), 0.0)).is_true()
	evt.elapsed_sec = 0.3
	assert_that(is_equal_approx(evt.opacity(), 0.75)).is_true()
	evt.elapsed_sec = 1.6
	assert_that(is_equal_approx(evt.opacity(), 1.0)).is_true()

	evt.curve = 4
	evt.elapsed_sec = 0.0
	assert_that(is_equal_approx(evt.opacity(), 0.0)).is_true()
	evt.elapsed_sec = 0.2
	assert_that(is_equal_approx(evt.opacity(), 1.0)).is_true()
	evt.elapsed_sec = 0.5
	var steep_val: float = evt.opacity()
	assert_that(steep_val < 1.0 and steep_val > 0.0).is_true()

	evt.duration_sec = 5.0
	evt.curve = 3
	evt.elapsed_sec = 0.0
	assert_that(is_equal_approx(evt.opacity(), 0.0)).is_true()
	evt.elapsed_sec = 0.25
	assert_that(is_equal_approx(evt.opacity(), 0.5)).is_true()
	evt.elapsed_sec = 2.5
	var log_val: float = evt.opacity()
	assert_that(log_val > 0.0 and log_val < 1.0).is_true()
	evt.elapsed_sec = 5.0
	assert_that(is_equal_approx(evt.opacity(), 0.0)).is_true()


func test_burden_transition_captions() -> void:
	var bm: Node = auto_free(BURDEN_SCRIPT.new())
	bm._load_burden_config()
	bm._burden_trigger_count = 0
	bm._lifetime_trigger_count = 0

	assert_that(bm._caption_bridge._caption_transitions.has("0_to_1")).is_true()
	assert_that(bm._caption_bridge._caption_transitions.has("2_to_3")).is_true()
	assert_that(bm._caption_bridge._caption_transitions.has("3_to_0_emergency")).is_true()
	assert_that(bm._caption_bridge._caption_transitions.has("3_to_0_normal")).is_true()
	assert_that(bm._caption_bridge._caption_transitions.has("2_to_1")).is_true()
	assert_that(bm._caption_bridge._caption_transitions.has("1_to_0")).is_true()

	var t0_1: Dictionary = bm._caption_bridge._caption_transitions["0_to_1"]
	assert_that(is_equal_approx(float(t0_1.get("offset_sec", 0.0)), 2.0)).is_true()
	assert_that(str(t0_1.get("curve", ""))).is_equal("EXPONENTIAL")

	var t2_3: Dictionary = bm._caption_bridge._caption_transitions["2_to_3"]
	assert_that(is_equal_approx(float(t2_3.get("offset_sec", 0.0)), 2.5)).is_true()
	assert_that(str(t2_3.get("curve", ""))).is_equal("EXPONENTIAL")

	var t_emerg: Dictionary = bm._caption_bridge._caption_transitions["3_to_0_emergency"]
	assert_that(is_equal_approx(float(t_emerg.get("offset_sec", 0.0)), 0.5)).is_true()
	assert_that(str(t_emerg.get("curve", ""))).is_equal("STEEP_EXPONENTIAL")

	var t2_1: Dictionary = bm._caption_bridge._caption_transitions["2_to_1"]
	assert_that(is_equal_approx(float(t2_1.get("offset_sec", 0.0)), 1.0)).is_true()
	assert_that(str(t2_1.get("curve", ""))).is_equal("LINEAR")

	var t1_0: Dictionary = bm._caption_bridge._caption_transitions["1_to_0"]
	assert_that(is_equal_approx(float(t1_0.get("offset_sec", 0.0)), 1.0)).is_true()
	assert_that(str(t1_0.get("curve", ""))).is_equal("LINEAR")

	var t_norm: Dictionary = bm._caption_bridge._caption_transitions["3_to_0_normal"]
	assert_that(is_equal_approx(float(t_norm.get("offset_sec", 0.0)), 2.5)).is_true()
	assert_that(str(t_norm.get("curve", ""))).is_equal("LOGARITHMIC")
	assert_that(is_equal_approx(float(t_norm.get("duration_sec", 0.0)), 5.0)).is_true()


func test_bd_climb_loop_phase() -> void:
	var cm: Node = auto_free(CAPTION_SCRIPT.new())
	cm._ready()

	cm.set_bd_climb_enabled(true)
	assert_that(cm._bd_climb_enabled).is_true()

	cm.report_bd_climb_width(0.25)
	assert_that(is_equal_approx(cm.get_bd_climb_width(), 0.25)).is_true()
	assert_that(is_equal_approx(cm.get_bd_climb_phase(), 0.25)).is_true()

	cm.report_bd_climb_phase(0.75)
	assert_that(is_equal_approx(cm.get_bd_climb_phase(), 0.75)).is_true()

	assert_that(cm.is_phase_within(0.5, 1.0)).is_true()
	assert_that(cm.is_phase_within(0.0, 0.5)).is_false()

	cm.report_stem_transient("BD-CLIMB", "peak", 0.8)
	assert_that(cm.was_stem_transient_recent("BD-CLIMB", "peak", 1.0)).is_true()
	assert_that(cm.was_stem_transient_recent("BD-CLIMB", "valley", 1.0)).is_false()
	assert_that(cm.was_stem_transient_recent("BD-MECH", "peak", 1.0)).is_false()

	var bm: Node = auto_free(BURDEN_SCRIPT.new())
	bm._load_burden_config()
	var caps: Dictionary = bm.get_bd_climb_width_captions()
	assert_that(caps.has("expanding")).is_true()
	assert_that(caps.has("converging")).is_true()
	assert_that(str(caps["expanding"].get("text", ""))).is_equal("[The walls widen]")
	assert_that(str(caps["converging"].get("text", ""))).is_equal("[Everything converges]")


func test_caption_timing_tolerance() -> void:
	var evt: RefCounted = CAPTION_SCRIPT.CaptionEvent.new()
	evt.offset_sec = 2.0
	evt.duration_sec = 2.0

	assert_that(evt.is_timing_accurate(2.0, 0.2)).is_true()
	assert_that(evt.is_timing_accurate(2.19, 0.2)).is_true()
	assert_that(evt.is_timing_accurate(2.21, 0.2)).is_false()
	assert_that(evt.is_timing_accurate(1.81, 0.2)).is_true()
	assert_that(evt.is_timing_accurate(1.79, 0.2)).is_false()


func test_caption_channel_isolation() -> void:
	var cm: Node = auto_free(CAPTION_SCRIPT.new())
	cm._ready()

	var dia: RefCounted = cm.schedule("Hello", 0, 0.0, 2.0)
	var bur: RefCounted = cm.schedule("[The world stills]", 1, 0.0, 2.0)

	assert_that(bur.surface_group).is_equal(1)
	assert_that(dia.surface_group).is_equal(0)

	cm.flush_all()
	assert_that(cm._active_events.is_empty()).is_true()
	assert_that(cm._event_queue.is_empty()).is_true()


func test_normal_3_to_0_transition() -> void:
	var bm: Node = auto_free(BURDEN_SCRIPT.new())
	bm._load_burden_config()

	var data: Dictionary = bm._caption_bridge._caption_transitions.get("3_to_0_normal", {})
	assert_that(not data.is_empty()).is_true()
	assert_that(is_equal_approx(float(data.get("offset_sec", 0.0)), 2.5)).is_true()
	assert_that(is_equal_approx(float(data.get("duration_sec", 0.0)), 5.0)).is_true()
	assert_that(str(data.get("curve", ""))).is_equal("LOGARITHMIC")

	var cm: Node = auto_free(CAPTION_SCRIPT.new())
	cm._ready()
	bm.schedule_transition_caption_explicit("3_to_0_normal")
	assert_that(true).is_true()
