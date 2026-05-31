extends RefCounted

## BurdenEventResult
## Structured result emitted when a Burden Event triggers.

## Metadata
var trigger_count: int = 0
var is_first: bool = false
var numbness_cap_reached: bool = false
var localization_key_suffix: String = ""
var noun_index: int = 0

## Phase A — The Stillness
var phase_a_duration_ms: int = 10000
var phase_a_localization_key: String = "BE_PHASE_A"

## Phase B — The Witness (may be silent)
var phase_b_text: String = ""
var phase_b_duration_ms: int = 0
var phase_b_localization_key: String = ""
var phase_b_variant_id: String = ""
var phase_b_cadence_ms: int = 0
var phase_b_word_count: int = 0

## Phase C — The Choiceless Choice
var phase_c_text: String = ""
var phase_c_duration_ms: int = 15000
var phase_c_hold_ms: int = 5000
var phase_c_mandatory_input_hold_ms: int = 5000
var phase_c_localization_key: String = "BE_PHASE_C"
var phase_c_legend_template: String = ""

## Phase D — Return to Tactical
var phase_d_text: String = ""
var phase_d_duration_ms: int = 2000
var phase_d_localization_key: String = "BE_PHASE_D"
