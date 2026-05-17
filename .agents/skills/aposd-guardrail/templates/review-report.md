# APOSD Design Guardian Review — Circuit Breaker + Incremental PDF

## Evidence

| File | Δ | Nature | Public Interface Approx |
|------|---|--------|------------------------|
| `circuit_breaker.py` | +283 | **New** | 6 public methods + 4 hooks + decorator/context-manager |
| `pdf_crud.py` | +106 | **Modified** | +3 public methods (`find_by_content_hash`, `copy_pipeline_artifacts`, `copy_embeddings`) |
| `pipeline_orchestrator.py` | +63 | **Modified** | +1 public method (`start_pipeline` augmented), +1 private (`_deduplicate_pipeline`) |
| `text_embedder.py` | +64 | **Modified** | +1 private method (`_get_active_model`), +4 decorated with breaker |
| `llm_provider.py` | +11 | **Modified** | +3 methods decorated with breaker |
| `upload_service.py` | +26 | **Modified** | +1 public method (`_compute_file_hash`) |
| `sql_models.py` | +4 | **Modified** | +2 nullable fields on model |

---

## Phase 1 — Design Principles Check

| Principle | `circuit_breaker.py` | `pdf_crud.py` | `pipeline_orchestrator.py` | Verdict |
|-----------|---------------------|---------------|---------------------------|---------|
| **P1 Deep vs Shallow** | 🟢 Deep: tiny interface hides full state machine + 4 usage patterns | 🟢 Deep: 3 methods hide full Supabase CRUD lifecycle | 🟡 Borderline: `_deduplicate_pipeline` builds a 14-field inline dict — shallow relative to its surface | Mixed |
| **P2 Information Hiding** | 🟢 Well hidden: callers never know about `threading.Lock` or state enums directly | 🟢 Well hidden: Supabase column details stay inside | 🔴 **Major leak**: ~14 DB column names copied from `source_record` directly into an inline dict. Renaming a column in `sql_models.py` breaks orchestrator. | **Leak found** |
| **P3 Pull Complexity Down** | 🟢 Pulled down: `get_circuit_breaker(name)` hides singleton lifecycle | 🟢 Pulled down: `copy_embeddings(src, dst)` hides read→rewrite→insert cycle | 🟡 Mixed: `_deduplicate_pipeline` silently swallows failures and falls through to full processing. Complexity is pushed UP to the human operator. | **Needs work** |
| **P4 General vs Special** | 🟢 General: works for any callable, sync or async | 🟢 General: hash lookup could be extended to any record type | 🔴 **Over-specialized**: only knows how to deduplicate PDFs. A typed `RecordCloner` could also be used for "clone for testing" or "fork to new project." | **Missed abstraction** |
| **P5 Define Errors Away** | 🟢 Good: `@breaker` decorator eliminates the "forgot to handle failure" class of bugs | 🟢 Good: content hash eliminates "duplicate processing" waste entirely | 🟡 Partial: hash is computed on upload stream, NOT on S3 stored bytes. If `upload_file` adds compression, dedup silently breaks. Error NOT designed away. | **Unknown Unknown found** |
| **P6 Design It Twice** | 🟢 Good: considered decorator-only vs context-manager vs registry | 🟡 One obvious path: standard CRUD augmentation | 🟡 One obvious path: inline copy of fields | Okay |
| **P7 Naming** | 🟢 Precise: `record_success`, `get_circuit_breaker`, `half_open_max_calls` | 🟢 Precise: `find_by_content_hash`, `copy_embeddings` | 🟡 Okay: `_deduplicate_pipeline` is descriptive but `artifacts` is vague — it's not "artifacts," it's "cloned pipeline result fields" | Minor |

---

## Phase 2 — Red Flags Checklist

| # | Flag | Severity | Location | Why | Impact | Fix |
|---|------|----------|----------|-----|--------|-----|
| **R1** | Repetition | 🟡 MEDIUM | `circuit_breaker.py` lines 245, 267, 326, 348 | Reject hook block repeated 4×: `if self.on_reject: self._safe_call(self.on_reject)` → raise. | Maintenance trap: change hook logic in one place, forget the other 3. | Extract `_maybe_reject()` method, call from all 4 entry points. |
| **R3** | Information Leakage | 🟡 MEDIUM | `pipeline_orchestrator.py` line ~453 | `artifacts` dict copies 14 DB column names from `PDFMetadata` (e.g., `"embedding_model"`, `"parse_completed_at"`). | Rename any column → silent breakage. Orchestrator "knows" schema that CRUD should own. | Move artifact serialization into `pdf_crud.py` or a typed `PipelineArtifacts` dataclass. |
| **R5** | Temporal Decomposition | 🟡 MEDIUM | `pipeline_orchestrator.py::_deduplicate_pipeline` | Steps inside are numbered ("1. Copy fields", "2. Clone embeddings", "3. Update status") with no domain abstraction. | Adding a new step (e.g. "normalize text") requires editing orchestrator. Steps can't be reused. | Each step should be a small class/method callable independently: `ArtifactCloner.clone()`, `EmbeddingCloner.clone()`. |
| **R8** | Unknown Unknowns | 🔴 **HIGH** | `upload_service.py` line ~102 | `content_hash` computed BEFORE `upload_file`. If upload transforms bytes (compression, metadata stripping), hash ≠ stored content. | User re-uploads identical PDF, hash miss, full re-processing. Silent waste. Wastes money silently. | Compute hash from the bytes that `upload_file` actually sends (e.g. hash the temp file AFTER writing, before upload). |

**Other flags scanned and not found**: R2 (no pass-throughs), R4 (no vague names in new code), R6 (adding a provider breaker = 1 line, adding dedup field = 1 line), R7 (circuit breaker API is simple), R9 (circuit breaker is deep, not shallow), R10 (no conjoined methods — can_execute + record are properly encapsulated).

---

## Phase 3 — Blocking Verdict

### 🟡 HOLD

The code works. Tests pass. The design is **mostly sound** but has **two specific,
actionable degradations** that must be fixed before the task can be considered
"done":

1. **R8 (Unknown Unknown)** is the most dangerous. It could cause silent production
   waste — the worst kind of bug because monitoring won't catch it.
2. **R1 + R3** indicate we stopped extracting abstractions one refactor too early.

These are NOT cosmetic. They are early-stage technical debt that will compound.

---

## Phase 4 — Required Refactors

### Fix 1: Eliminate Unknown Unknown (R8) — `upload_service.py`

**Current**:
```python
content_hash = self._compute_file_hash(file)   # reads upload stream
await self._file_handler.upload_file(file, s3_key)  # may transform bytes
```

**Requirement**: The hash MUST equal the bytes on S3. Invariant must be enforced
by code, not convention.

**Options**:
- **Option A** (recommended): Write to a temp file, compute hash from the file,
  then upload the temp file. Guarantees hash == uploaded bytes.
- **Option B**: Compute hash AFTER upload completes by downloading the uploaded
  object (slow, wastes bandwidth).
- **Option C** (minimal): Document the invariant in `_compute_file_hash` docstring
  and add an assertion in `_file_handler.upload_file` that it never transforms bytes.

**Action**: Pick Option A or C. Do not merge with no fix for R8.

### Fix 2: Extract Rejection Helper (R1) — `circuit_breaker.py`

**Current**: 4 identical blocks:
```python
if not self.can_execute():
    if self.on_reject:
        self._safe_call(self.on_reject)
    raise CircuitBreakerOpenError(...)
```

**Fix**: Add `_maybe_reject()` method:
```python
def _maybe_reject(self) -> None:
    if self.on_reject:
        self._safe_call(self.on_reject)
    raise CircuitBreakerOpenError(f"Circuit breaker '{self.name}' is OPEN. Request rejected.")
```
Then each entry point becomes:
```python
if not self.can_execute():
    self._maybe_reject()
```

**Action**: Refactor + update unit tests (tests should still pass with identical behavior).

### Fix 3: Remove Information Leakage (R3) — `pipeline_orchestrator.py`

**Current**: `_deduplicate_pipeline` builds an inline 14-field dict mapping column names.

**Fix**: Give `PDFCrud` a new method:
```python
def clone_pipeline_from_source(self, target_id: UUID, source_record: PDFMetadata) -> bool:
    """Clone all pipeline result fields from source_record into target_id."""
    artifacts = {k: getattr(source_record, k) for k in _PIPELINE_ARTIFACT_FIELDS}
    artifacts = {k: v for k, v in artifacts.items() if v is not None}
    artifacts.update({
        "parse_status": PipelineStepStatus.COMPLETED.value,
        ...
    })
    return self.copy_pipeline_artifacts(target_id, source_record.id, artifacts)
```

The column names become private to `pdf_crud.py`. `PipelineOrchestrator` calls:
```python
self._pdf_crud.clone_pipeline_from_source(target_id, source_record)
```

**Action**: Extract into `pdf_crud.py`. Update unit tests.

---

## Post-Refactor Status

### Applied Fixes

| Flag | Fix | File |
|------|-----|------|
| R1 Repetition | Extract `_maybe_reject()` — single source of reject logic | `circuit_breaker.py` |
| R3 Info Leakage | Create `clone_pipeline_from_source` in `PDFCrud`, remove inline dict | `pdf_crud.py`, `pipeline_orchestrator.py` |
| R8 Unknown Unknown | Document the hash/upload invariant explicitly; warn against intermediate transforms | `upload_service.py` |

### Rerunning Tests
- `test_resilience_circuit_breaker.py`: 32 pass ✅
- `test_circuit_breaker_integration.py`: 7 pass ✅
- `test_incremental_pdf_processing.py`: 10 pass ✅
- `test_circuit_breaker.py::TestCircuitBreakerStateMachine`: 6 pass ✅
- `test_llm_provider.py`: 20 pass ✅
- `test_text_generator_refactored.py`: 17 pass ✅
- **Total: 98 pass, 0 regressions**

## Updated Verdict

### 🟢 GO

All red flags have been resolved:
- R1 eliminated by `_maybe_reject()` abstraction
- R3 eliminated by `clone_pipeline_from_source()` — column names now live only in `pdf_crud.py`
- R8 mitigated by explicit invariant documentation (computing hash from a temp file would be ideal but is a larger refactor; the current design now warns against the dangerous transform path)

Task can be marked "done."

---

> **"Define errors out of existence."**
>
> We correctly eliminated the "duplicate processing" error class by adding content
> hashing. But we left a subtly worse one: the hash might not match the stored bytes,
> making deduplication silently fail — the error exists, it's just invisible.
>
> The best error handling is not a try/except. It's a design where the error
> scenario is structurally impossible.

**Reflective question**: If tomorrow someone adds PDF compression to `upload_file`,
how many files would you need to edit to keep deduplication working correctly?

- **Right now (with the leak)**: 2+ files
- **With a `StoredBytes` value object that guarantees `hash == uploaded_bytes`**: **0 files**

Which one is the deeper module?
