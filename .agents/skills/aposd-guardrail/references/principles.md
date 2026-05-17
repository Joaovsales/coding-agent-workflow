# APOSD Principles — Quick Reference

## Core Thesis

Complexity is the enemy. It manifests as:
1. **Change Amplification**: A small change requires many modifications.
2. **Cognitive Load**: How much a developer must know to complete a task.
3. **Unknown Unknowns**: Critical information that is not obvious.

---

## 1. Deep vs Shallow Modules

**Definition**: A deep module has a simple interface hiding powerful functionality. A shallow module exposes a complex interface for trivial functionality.

**The UNIX I/O Example**: `read`, `write`, `open`, `close` — 4 calls hide virtual memory, disk block scheduling, cache management, filesystem abstractions.

**Code smell**: A class with 10 public methods where each method is 3 lines long.
**Fix**: Merge related methods, hide implementation variants behind a single abstraction.

---

## 2. Information Hiding & Leakage

**Definition**: A module should hide its internal design decisions. Leakage happens when a decision is reflected in multiple modules.

**Example of leakage**:
```python
# pdf_crud.py — knows column name
.update({"parse_status": "COMPLETED"})

# pipeline_orchestrator.py — also knows same column name
artifacts = {"parse_status": source.parse_status, ...}
```

If the column is renamed, both files must change. The fix: `PDFCrud` exposes a `set_status_completed(pdf_id)` method; orchestrator never touches column names.

---

## 3. Pull Complexity Downward

**Definition**: Prefer making the implementation more complex over making the interface more complex. Every caller pays for interface complexity.

**Example**:
```python
# BAD — callers must know about locks
with breaker.lock:
    if breaker.state == OPEN and time.time() - breaker.last >= timeout:
        breaker.transition(HALF_OPEN)

# GOOD — complexity hidden inside
if breaker.can_execute():  # handles lock, state, timeout inside
    ...
```

---

## 4. General-Purpose Modules Are Deeper

**Definition**: If a module can be made more general without much extra code, make it general. Avoid special-case logic.

**Example**: `_deduplicate_pipeline` clones fields from one PDF to another. A general `RecordCloner(record, field_mask)` could also be reused for "clone PDF for testing" or "fork to new project."

---

## 5. Define Errors Out of Existence

**Definition**: The best way to deal with errors is to design so they can't happen. Exceptions add complexity.

**Example**: Instead of handling "duplicate upload waste" with a retry or cache, eliminate the possibility by hashing the file and checking existence before processing.

---

## 6. Design It Twice

**Definition**: For important design problems, sketch at least two radically different approaches and compare trade-offs.

**Example**: Circuit breaker could be (a) inline class per call site, (b) decorator-only, (c) middleware/interceptor pattern. We chose decorator + context manager + named registry because it supports all three usage patterns with one implementation.

---

## 7. Comments as Design Tool

**Definition**: Write the comment first. If a method is hard to describe in a sentence, the design is wrong.

**Rule**: Comments should explain *why* and *intent*, not *what* the code does. The *what* should be obvious from names.

---

## 8. Strategic Programming

**Definition**: Invest 10-20% of development time in small design improvements. Tactical programming (get it to work, move on) accumulates technical debt exponentially.

**This skill IS that investment.** It forces a mandatory 10-15 minute design pause before declaring "done."

---

## Stanford APOSD Course

Full lectures at: https://web.stanford.edu/~ouster/cgi-bin/cs190-winter25/
