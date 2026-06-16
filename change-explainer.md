-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

name: change-explainer
description: Produce a design-oriented code review report after any code generation, modification, refactor, deletion, migration, optimization, or architectural change only if the final token(s) of the user's message are exactly use explainer (case-insensitive). If the user's message does not end with use explainer, do not generate the explainer report. Respond normally instead. The goal is to expose every meaningful design decision so reviewers can validate correctness, architecture, file organization, behavior changes, and requirement alignment without reading the full implementation. Otherwise, do not generate the explainer report and provide the normal response only.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Change Explainer (Ultimate Review Mode)

## Primary Goal

The purpose is NOT to summarize code.

The purpose is to expose every design decision introduced by the implementation.

A reviewer should be able to understand:

* what changed
* why it changed
* where responsibilities moved
* how behavior changed
* what assumptions were introduced
* what tradeoffs were made
* what risks remain

without reading the full codebase.

---

# Core Principle

Explain decisions.

Do NOT explain code.

Bad:

"Added a new function."

Good:

"Introduced a separate validation stage before persistence to isolate business validation from storage concerns."

---

# Pre-Analysis Requirements

Before writing the report:

1. Inspect all modified files.
2. Inspect the complete diff.
3. Reconstruct affected:

   * call chains
   * event flows
   * data flows
   * dependency chains
   * lifecycle transitions
4. Identify every design-relevant modification.
5. Separate:

   * design changes
   * mechanical changes

If a diff is unavailable, explicitly state:

"Analysis is based only on currently visible code and may miss hidden modifications."

---

# What MUST Be Reported

Report every modification involving:

## Architecture

* module boundaries
* file placement
* responsibility ownership
* dependency direction
* layering
* service decomposition
* plugin mechanisms
* registration systems

## API Contracts

* public interfaces
* function signatures
* component props
* route contracts
* schema changes
* configuration options
* environment variables
* CLI interfaces

## Control Flow

* execution order
* lifecycle timing
* initialization
* cleanup
* hook registration
* dispatch flow
* orchestration logic

## Data Flow

* ownership
* transformations
* normalization
* serialization
* parsing
* validation
* caching
* synchronization

## State Management

* source of truth
* state movement
* persistence
* invalidation
* memoization

## Error Strategy

* retries
* fallback logic
* degradation paths
* exception boundaries
* observability

## Security

* trust boundaries
* sanitization
* authentication
* authorization
* secret handling

## Performance

* batching
* async execution
* concurrency
* lazy loading
* caching
* resource lifecycle

## Compatibility

* migration paths
* backward compatibility
* default behavior changes
* feature flags
* rollout assumptions

## Testing

* what behaviors are verified
* what is intentionally untested
* test strategy implications

## Tradeoffs

* alternatives considered
* alternatives rejected
* assumptions introduced
* deliberate limitations

---

# What MUST NOT Be Reported

Do not explain:

* syntax
* framework APIs
* obvious control statements
* formatting
* import adjustments
* boilerplate
* trivial variable plumbing

unless they have design implications.

---

# Report Structure

---

## Main Change Thread

One sentence only.

Describe the primary design change.

Example:

Main change thread:
Move request validation from controller layer into a dedicated validation pipeline before persistence.

---

## 1. Executive Summary

List the most important design changes.

Prioritize by architectural impact.

Format:

1. ...
2. ...
3. ...

---

## 2. Call Chain Changes

Required whenever execution paths changed.

Format:

Before:

A
→ B
→ C

After:

A
→ B
→ D
→ E
→ C

For each inserted/removed stage explain:

* responsibility
* reason
* behavior impact

Do NOT merely describe function calls.

Explain why the chain changed.

---

## 3. Data Flow Changes

Required whenever data movement changed.

Format:

Before:

Input
→ Parser
→ Storage

After:

Input
→ Parser
→ Validation
→ Normalization
→ Storage

For every new stage:

* ownership
* responsibility
* design rationale
* side effects

---

## 4. File Responsibility Changes

For each affected file:

### File

path/to/file

Previous responsibility:

...

New responsibility:

...

Reason for change:

...

If a new file was introduced:

Why does this file exist?

Why was this not placed elsewhere?

What architectural boundary does it represent?

---

## 5. Design Decision Ledger (Most Important Section)

Every design-relevant modification gets an entry.

### Decision N

Location:

...

Change:

...

Design intention:

...

Alternatives:

* A
* B
* C

Why current approach won:

...

Potential mismatch with user intent:

...

Risk level:

Low / Medium / High

This section should be exhaustive.

If a design decision exists, it must appear here.

---

## 6. Behavioral Changes

List all observable behavior changes.

Including:

* default values
* timing
* ordering
* retries
* lifecycle behavior
* cache behavior
* persistence behavior
* concurrency behavior

Format:

Behavior:

...

Before:

...

After:

...

Impact:

...

---

## 7. Hidden Side Effects

List non-obvious consequences.

Examples:

* dependency coupling
* initialization timing shifts
* cache invalidation changes
* memory growth
* extra network requests
* altered failure visibility

Even minor ones should be listed.

---

## 8. Tradeoffs and Assumptions

Document:

* assumptions introduced
* limitations accepted
* intentionally deferred work
* rejected alternatives

---

## 9. Risk Review (Self-Critique)

Actively audit the implementation.

For each risk:

Risk:

...

Why it exists:

...

If requirements were interpreted differently:

...

Consequence:

...

Mitigation:

...

---

## 10. Requirement Alignment Audit

Explicitly verify:

Requirement:

...

Implementation:

...

Status:

✓ Fully aligned

△ Partially aligned

✗ Potentially misaligned

This section is mandatory.

The goal is to catch misunderstandings before review.

---

## 11. Unchanged Areas

List areas that might appear affected but were intentionally untouched.

Format:

Not modified:

* ...
* ...
* ...

Reason:

...

---

# Final Validation Rule

Before submitting the report, verify:

If the reviewer never opens the code:

Can they understand:

* architecture changes
* file organization changes
* data flow changes
* call chain changes
* behavior changes
* design rationale
* tradeoffs
* risks
* requirement alignment

If any answer is NO, the report is incomplete.
