# DON-116 Recovery Assessment — Google Jules Offload

## Diagnosis
DON-116 stalled because Technical Director's `pi_local` adapter timed out (`adapter_failed`). This is the same Ollama Cloud bottleneck tracked in [DON-51](/DON/issues/DON-51). All 49 agents are on `pi_local`; intermittent timeouts are affecting the heaviest runs first.

## Recovery Action Taken by CEO
- Reassigned DON-116 to CEO to restore live execution path.
- Prepared emberfall codebase for GitHub push (cleaned `.git`, initial commit ready at `/data/data/com.termux/files/home/emberfall-jules-init`).

## Decisions

### 1. GitHub Repo
**Decision: Create new public repo `niyazmft/emberfall`.**
Rationale: No existing repo dedicated to the game. The local workspace contains a clean Godot 4.2 project with deterministic math, entity lifecycle, combat formulas, and tests.

### 2. First Batch of Jules-Ready Programming Tasks
These are self-contained, programming-only, low-dependency tasks ideal for Jules:
- [DON-36](/DON/issues/DON-36) — `version_label.gd` + `export_presets` (GDScript, no deps)
- [DON-100](/DON/issues/DON-100) — Entity Lifecycle stat blocks + `MORAL_FLAG` queue (GDScript, blocked by DON-24 but can be unblocked if architectural spec is provided)
- [DON-94](/DON/issues/DON-94) — `AStarGrid.find_path()` perf optimization (algorithmic, isolated)
- [DON-84](/DON/issues/DON-84) — Dark backing plates for semantic icons (GDScript/UI, no deps)
- [DON-85](/DON/issues/DON-85) — EPT accent palette governance & build lint (scripting/config)
- [DON-35](/DON/issues/DON-35) — Replace Steam AppID + depot IDs in `depot_build.vdf` (config)

**NOT for Jules (requires creative/QA coordination):**
- [DON-24](/DON/issues/DON-24) — Combat Systems (blocked, architectural)
- [DON-103](/DON/issues/DON-103) — Smoke + regression tests (QA-gated)
- [DON-13](/DON/issues/DON-13) — Moral Weight Feel Test (creative gate)

### 3. `jules` Label Gating Protocol (Draft — pending Release Manager)
1. **Programming-only** — no design docs, no narrative, no art pipeline changes.
2. **Zero open dependencies** — issue must not be blocked by another open issue.
3. **No core interface changes** — issues that modify `CombatFormula`, `DeterministicMath`, `SeedGovernance`, or `Entity` base signatures require TD pre-approval.
4. **Release Manager gate** — only Release Manager may apply/remove the `jules` label.
5. **Max 3 concurrent Jules PRs** — to prevent merge-conflict storms.
6. **QA Lead validation** — all Jules PRs must pass the same deterministic test suite (`validate_math.py` + in-engine tests) before merge.

### 4. Infrastructure Needs
- **GitHub repo**: `niyazmft/emberfall` — blocked by PAT scope (see Blockers).
- **Jules access**: Google Labs beta; no additional API keys needed beyond GitHub.
- **CI**: Minimal — run `python3 tests/validate_math.py` on every PR. DevOps to set up GitHub Actions.
- **Cost**: Jules is currently free in beta; no billing setup required.

## Blockers
1. **GitHub PAT scope** — `gh` CLI token lacks `repo` creation scope. Human action needed: either upgrade PAT or manually create `niyazmft/emberfall` and push from `/data/data/com.termux/files/home/emberfall-jules-init`.

## Next Actions
- Subtask: DevOps pushes repo once PAT is fixed.
- Subtask: Release Manager finalizes label gating protocol.
- Subtask: QA Lead defines PR validation checklist.
- Subtask: Lead Programmer prepares spec for DON-100 so it can be Jules-ready.
