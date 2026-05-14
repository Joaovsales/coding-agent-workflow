# A Philosophy of Software Design – Principles & Red Flags

## Core Thesis
Complexity is the enemy. It manifests as:
1. **Change Amplification**: A small change requires many modifications.
2. **Cognitive Load**: How much a developer needs to know to complete a task.
3. **Unknown Unknowns**: Critical information that is not obvious.

## Strategic Programming
- **Rule**: The primary goal is great design that happens to work.
- **Investment**: Spend 10-20% of development time on small design improvements.
- **Tactical Programming**: Getting it to work quickly. Leads to technical debt.

## Deep Modules
- **Ideal**: Powerful functionality through a simple interface.
- **Unix I/O**: 5 calls hide enormous complexity.
- **Shallow Module**: Complex interface for small functionality.

## Information Hiding & Leakage
- A module should hide its internal implementation decisions.
- **Leakage**: When a design decision is reflected in multiple modules.
- **Symptom**: Changing one implementation detail forces changes elsewhere.

## Pull Complexity Downward
- Prefer to make the module's implementation more complex rather than making its interface more complex.
- The interface is what every caller pays for.

## General-Purpose Modules are Deeper
- If a module can be general without much extra code, make it general.
- Avoid special cases.

## Different Layer, Different Abstraction
- Adjacent layers should provide a different level of abstraction.
- If a method does roughly the same work as its caller, it's a red flag.

## Define Errors Out of Existence
- The best way to deal with errors is to design so they can't happen.
- Exceptions add complexity. Minimize them.

## Design it Twice
- For important design problems, sketch at least two radically different approaches.
- Compare trade-offs before committing.

## Comments as Design Tool
- Write comments first. If a method is hard to describe, the design is wrong.
- Focus on WHY and intent, not WHAT the code does.

## Names
- Names should be precise, consistent, and obvious.
- If a variable needs a comment to explain it, the name is bad.
- Avoid vague names: `data`, `result`, `count`, `tmp`, `obj`.

## Red Flags
1. **Shallow Module**: Simple functionality, complex interface.
2. **Information Leakage**: Implementation detail visible in multiple places.
3. **Temporal Decomposition**: Split by time/order rather than by functionality.
4. **Overexposure**: Interface requires caller to know too much.
5. **Pass-Through Method/Variable**: Just forwarding without adding value.
6. **Repetition**: Same pattern repeated. Missing abstraction.
7. **Special-General Mixture**: Some callers use a special case, others use general.
8. **Conjoined Methods**: Methods that must be called in a specific order.
9. **Obscured by Repetition**: Common cases require same boilerplate as rare cases.
10. **Hard to Describe**: Can't write a concise comment for a module.
