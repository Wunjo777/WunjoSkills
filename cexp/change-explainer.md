---
name: cexp
description: Explain completed code changes using a strict four-step code review format. Use whenever Coding Agent has created, modified, refactored, or deleted code and is preparing the final delivery. Focus on helping the user review architecture, call paths, dependencies, behavior changes, design decisions, and possible mismatches with requirements.
disable-model-invocation: true
---
# Change Explainer
## Purpose
The goal is not to summarize code.
The goal is to let the user review the implementation without reading the entire diff.
Every explanation must follow the exact four-step structure below.
If the actual diff cannot be inspected, explicitly state that limitation and explain only from available information.
---
# Pre-Analysis Requirements
Before generating the explanation:
1. Inspect every changed file.
2. Inspect all diffs.
3. Reconstruct the complete execution path affected by the change.
4. Reconstruct all module dependencies introduced, removed, or modified.
5. Identify all design decisions.
6. Identify all assumptions made by the implementation.
7. Identify anything that may differ from the user's original intent.
Do not skip these steps.
---
# Output Structure
Always use exactly the following structure.
---
## Step 1 — Changed File List
Group files by change type.
Format:
```text
Step 1. Changed Files
[Created]
- path/fileA
  - purpose
- path/fileB
  - purpose
[Modified]
- path/fileC
  - what changed
- path/fileD
  - what changed
[Deleted]
- path/fileE
  - why removed
```
Rules:
* Every changed file must appear.
* Do not omit files.
* Explain why each file exists in the change.
* Explain architectural responsibility when relevant.
---
## Step 2 — Architecture Graphs
Generate BOTH diagrams.
### 2.1 Function Call Chain Graph
Use plain text diagrams.
Example:
```text
User Action
    ↓
MainActivity.onCreate()
    ↓
VoiceManager.start()
    ↓
AvatarController.enterListening()
    ↓
AnimationPlayer.play()
```
Rules:
* Include all changed functions.
* Include upstream callers.
* Include downstream effects.
* Show actual execution order.
* Multiple branches must be visualized.
Example:
```text
Input
 ├─→ Parser.parse()
 │      ↓
 │   Validator.check()
 │      ↓
 │   Repository.save()
 │
 └─→ Logger.record()
```
---
### 2.2 File Dependency Graph
Show relationships between files/modules.
Example:
```text
MainActivity.kt
      ↓
VoiceManager.kt
      ↓
AvatarController.kt
      ↓
AnimationPlayer.kt
```
For branching dependencies:
```text
AvatarController.kt
 ├─→ AnimationPlayer.kt
 ├─→ AudioManager.kt
 └─→ StateMachine.kt
```
Rules:
* Must reflect actual dependency direction.
* Must include newly introduced dependencies.
* Must include removed dependencies when relevant.
* Must include ownership boundaries.
---
## Step 3 — Precise Function/Class Explanation
Explain every modified:
* class
* interface
* object
* struct
* enum
* function
* method
* hook
* service
* component
Format:
```text
FunctionName()
Purpose:
One sentence.
Input:
- parameterA
- parameterB
Output:
- return value
Behavior:
One sentence explaining exactly what it does.
```
Example:
```text
calculateExposure()
Purpose:
Computes target exposure from scene luminance.
Input:
- averageLuminance
Output:
- targetExposure
Behavior:
Maps luminance into exposure space and clamps the result.
```
Rules:
* One entity at a time.
* No vague descriptions.
* State purpose, input, output, and behavior.
* If side effects exist, explicitly state them.
Bad:
```text
Handles exposure logic.
```
Good:
```text
Converts average scene luminance into a clamped exposure multiplier and stores it in the adaptation buffer.
```
---
## Step 4 — Design Decisions and Intent Review
This is the most important section.
List every design-bearing decision.
Format:
```text
Design Decision
What changed:
...
Reason:
...
Impact:
...
Needs confirmation:
...
```
Must include:
* Architecture decisions
* Ownership changes
* Data flow changes
* Control flow changes
* API changes
* Interface changes
* State management changes
* Error handling changes
* Performance changes
* Threading/concurrency changes
* Caching changes
* Serialization changes
* Compatibility changes
* Assumptions
* Tradeoffs
For anything that may not exactly match the user's request:
```text
Needs confirmation:
Current implementation does X.
Original request may imply Y.
Please confirm whether X or Y is desired.
```
Never hide uncertainty.
Always explicitly call out potential mismatches.
---
# Explanation Rules
Always prioritize reviewability over brevity.
Do not explain line-by-line code.
Do not produce generic summaries.
Name actual files, functions, classes, modules, services, hooks, routes, shaders, components, or APIs whenever possible.
Prefer:
```text
MainActivity.onCreate()
      ↓
VoiceManager.start()
      ↓
AvatarController.enterListening()
```
instead of:
```text
Application initializes voice functionality.
```
Prefer:
```text
BlendPS()
Purpose:
Combines GI result with original frame.
```
instead of:
```text
Handles rendering.
```
Every explanation should allow the user to understand:
1. Which files changed.
2. Which functions execute.
3. Which files depend on which.
4. What every modified entity does.
5. Which design decisions were made.
6. Which decisions may not match the original intent.
If no code changed:
```text
No code changes detected.
```
and explain any non-code action performed.
