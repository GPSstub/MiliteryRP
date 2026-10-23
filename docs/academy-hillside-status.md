# Hillside campus checkpoint — 2026-10-23

User requested pushing the current work to main before finishing the rebuild.

## Saved map versus Studio-only work

MilitaryRP.rbxlx and assets/academy/AcademyCampus.rbxmx contain the last saved flat-campus version (18 buildings). They do NOT contain the later hillside terrain and replacement drill ground.

The previous Studio session applied building rotations/elevations, removed 200 room partitions, replaced the drill-ground geometry while retaining six ExamPositions areas, and generated terrain and 297 trees. That session is no longer open and no newer map snapshot was found. Do not claim the hillside build is saved or verified.

Automatic approval review hit a usage limit before the final eastern-terrain correction, extra forest and formation integration tests. These remain incomplete. Current plan files are work-in-progress and may differ from the last displayed Studio scene.

## Recovery materials

- assets/academy/hillside-plan.json: authored layout and terrace elevations.
- assets/academy/hillside-environment.json: new road/drill scenery data.
- tools/map/rework_academy.py: scene planning source (later layout corrections also exist in the JSON checkpoint).
- tools/map/hillside_height.luau: terrain height rules.
- tools/map/hillside-checkpoint/: exact staging-dependent layout script, terrain strips and extra forest script retained from temporary workspace. These are edit-time recovery references, NOT safe one-click installers. Review existing state and stage HillsideAdditions before applying the layout script; running it twice would transform geometry twice.

Do not deploy until the rebuilt map is saved and Studio multiplayer/DataStore tests are complete. The prior flat version had a successful single-character 1F-to-4F traversal check. CLI regression tests could not run because Luau CLI/compiler were not installed.
