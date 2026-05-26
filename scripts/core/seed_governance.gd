class_name SeedGovernance
## Deterministic seed governance for procedural generation.
## Implements SHA-256 truncated to 64-bit as specified in
## system-specification-core.md §6.
##
## All hash() calls are platform-agnostic and reproducible.

# ── Internal ────────────────────────────────────────────────────────
const _BLACKLISTED_SEEDS: Array[int] = []

# ── Core Hash ───────────────────────────────────────────────────────
static func hash_seed(input: String) -> int:
	## SHA-256 of UTF-8 input, truncated to the first 64 bits,
	## returned as a signed 63-bit non-negative integer.
	##
	## We mask with 0x7FFFFFFFFFFFFFFF so the result is always positive and
	## avoids signed/unsigned drift between platforms (Godot signed int64 vs.
	## Python arbitrary-precision int).  This matches the spec's requirement
	## for "platform-agnostic" 64-bit truncation.
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(input.to_utf8_buffer())
	var bytes: PackedByteArray = ctx.finish()
	# Truncate to 63-bit positive: concatenate first 8 bytes, mask sign bit
	var h: int = 0

	for i: int in range(8):
		h = (h << 8) | (bytes[i] & 0xFF)
	return h & 0x7FFFFFFFFFFFFFFF


static func hash_int(seed: int, salt: String) -> int:
	## Convenience wrapper: hashes seed + salt as a single string.
	return hash_seed(str(seed) + salt)


static func modulo_from_seed(seed: int, salt: String, modulus: int) -> int:
	## Returns hash(seed + salt) mod modulus, always non-negative.
	var h: int = hash_int(seed, salt)
	# Godot's % on negative numbers can be negative; fix with abs or fposmod logic.
	var mod: int = h % modulus
	if mod < 0:
		mod += modulus
	return mod


# ── Room & Encounter Generation ──────────────────────────────────
static func seed_room_topology(seed: int, room_index: int, template_count: int) -> int:
	## §6.2: seed_room_topology(K) = hash(seed + "TOPO" + K) mod N_TEMPLATES
	return modulo_from_seed(seed, "TOPO" + str(room_index), template_count)


static func seed_encounter(seed: int, room_index: int, encounter_bank_size: int) -> int:
	## §6.2: seed_encounter(K) = hash(seed + "ENC" + K) mod N_ENCOUNTER_BANK
	return modulo_from_seed(seed, "ENC" + str(room_index), encounter_bank_size)


static func seed_echo(seed: int, room_index: int, echo_bank_size: int) -> int:
	## §6.2: seed_echo(K) = hash(seed + "ECHO" + K) mod N_ECHO_BANK
	return modulo_from_seed(seed, "ECHO" + str(room_index), echo_bank_size)


# ── Seed Validation (Blacklist Rules) ─────────────────────────────
static func validate_seed(seed: int, room_params: Dictionary) -> bool:
	## Returns true if seed passes all blacklist rules from §6.1.
	##
	## room_params expected keys:
	##   "template_count": int, "encounter_bank_size": int,
	##   "rooms_per_biome_min": int, "rooms_per_biome_max": int,
	##   "biome_count": int
	## TODO: implement full blacklist checks in A3/A5 when topology engine exists.
	if seed in _BLACKLISTED_SEEDS:
		return false
	return true
