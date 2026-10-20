# MilitaryRP developer agent guidance

Before modifying Roblox scripts, consult `.agents/skills/roblox-dev-skill/SKILL.md` and relevant linked references. For RemoteEvent security use `.agents/skills/roblox-networking/SKILL.md`; for DataStore/cross-server use `.agents/skills/roblox-data/SKILL.md`; for Luau strict typing use `.agents/skills/luau-types/SKILL.md`.

Vendored skill provenance and pinned commits are in `.agents/skills/SOURCES.md`. These files are guidance, not executable Roblox modules.

Maintain the original gameplay and secure server-side authority. Preserve the completed `MilitaryRP.rbxlx` containing the actual map; `tools/build_place.py` only generates `MilitaryRP.test.rbxlx`. To update scripts inside the complete map use `python3 tools/sync_place.py`. Run `python3 tools/test.py` with the Luau CLI installed, and perform Roblox Studio multiplayer/DataStore integration tests before deploying.
