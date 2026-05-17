# Red Flags Catalog — Symptoms & Refactor Recipes

A complete guide to spotting and fixing each APOSD red flag.

---

## R1: Repetition

**Symptom**: The same code pattern appears 3+ times. Copy-paste with minor variations.

**Example**:
```python
if self.on_reject:
    self._safe_call(self.on_reject)
raise CircuitBreakerOpenError(...)
```
Appears in `_sync_decorator`, `_async_decorator`, `__enter__`, `__aenter__`.

**Fix**: Extract a helper method `_maybe_reject()` and call it from all 4 locations.

**Why it matters**: Repetition is a missing abstraction screaming to exist. Every
repeated block is a future bug when one copy gets updated and the others don't.

---

## R2: Pass-Through Method

**Symptom**: A method that does nothing but call another method with the same (or nearly same) signature.

**Example**:
```python
def get_user_name(user_id):
    return database.get_user_name(user_id)  # Pass-through
```

**Fix**: Remove the pass-through. Call the inner method directly. Or, if the
pass-through adds value (adapter pattern), make that value explicit.

---

## R3: Information Leakage

**Symptom**: A design decision (column name, state enum value, API endpoint) is used
in more than one module.

**Example**:
```python
# pdf_crud.py
.update({"status": "COMPLETED"})

# pipeline_orchestrator.py
artifacts = {"status": source.status}
```

**Fix**: The module that owns the data should own ALL knowledge of its structure.
Expose domain-specific methods: `mark_completed(pdf_id)`, `clone_artifacts(source, target)`.

---

## R4: Vague Names

**Symptom**: Variable or function name that requires reading the body to understand.

**Red flag names**: `data`, `result`, `count`, `tmp`, `obj`, `item`, `process`, `handle`, `do_stuff`

**Fix**: Replace with names that encode the type + intent + context:
- `data` → `embedding_batch` or `parsed_text_content`
- `result` → `deduplication_outcome` or `breaker_state_transition`
- `process` → `enqueue_pdf_pipeline` or `flush_embedding_cache`

---

## R5: Temporal Decomposition

**Symptom**: Code is organized by WHEN things happen, not by WHAT they do.

**Example**:
```python
# BAD — split by step
class PipelineRunner:
    def step1_parse(self, pdf): ...
    def step2_chunk(self, pdf): ...
    def step3_embed(self, pdf): ...
```

**Fix**: Organize by domain object:
```python
class PDFParser: ...
class TextChunker: ...
class Embedder: ...
```
Each is independently testable and reusable.

---

## R6: Change Amplification

**Symptom**: A small requirement change requires touching many files.

**Example**: Adding a new pipeline step requires editing `PipelineOrchestrator`,
`PDFCrud`, `sql_models.py`, AND migration files.

**Fix**: Use plugin/registry pattern. Steps register themselves:
```python
PipelineRegistry.register("parse", PDFParserStep())
PipelineRegistry.register("chunk", TextChunkerStep())
```
Adding a new step = adding one file + one registration line.

---

## R7: High Cognitive Load

**Symptom**: To use a module's public API, the caller needs to know about internal
implementation details.

**Example**: Caller must know the circuit breaker uses `threading.Lock`, or must
know the PDF table has a `content_hash` column.

**Fix**: Hide everything. The caller should only know: "I give this function a name
and it gives me a breaker." The caller should never see `CircuitBreakerState.HALF_OPEN`.

---

## R8: Unknown Unknowns

**Symptom**: Hidden side effects, implicit contracts, or mutable shared state that
violates the principle of least surprise.

**Example**:
```python
content_hash = _compute_file_hash(file)
upload_file(file)  # Side effect: file position is now EOF
# Later: something else reads file — gets empty bytes!
```

Or:
```python
# UploadService computes hash BEFORE upload, but if upload adds compression,
# the S3 content ≠ hashed content. Deduplication silently breaks.
```

**Fix**: Make effects visible. Return the hash AND the bytes. Or compute hash from
the same bytes that go to storage. Add assertions that document invariants.

---

## R9: Shallow Module

**Symptom**: Simple functionality hiding behind a complex interface. Many parameters,
many preconditions, many return-value variations.

**Example**: A function that takes 6 boolean flags to control 3 lines of logic.

**Fix**: Split into smaller, composable functions. Or use the Builder / Strategy
pattern so callers compose behavior, not configure it.

---

## R10: Conjoined Methods

**Symptom**: Two or more methods that must be called in a specific order. The state
machine is encoded by convention, not by structure.

**Example**:
```python
breaker.record_failure()
# Oops — forgot to check breaker.can_execute() first!
```

**Fix**: Make ordering impossible to violate:
```python
with breaker.execute():  # handles can_execute + record_success/failure
    do_work()
```

Or:
```python
@breaker  # decorator handles everything
async def do_work(): ...
```

---

## Severity Guide

| Severity | When to assign | Action required |
|----------|----------------|-----------------|
| LOW | Minor style, naming could be better, cosmetic | Note it, but doesn't block |
| MEDIUM | Missing abstraction, minor info leak, 2× repetition | Must fix before merge |
| HIGH | Major info leak, unknown unknown, shallow module | Redesign before merge |
| CRITICAL | Conjoined methods with no enforcement, security leak | STOP — do not merge |
