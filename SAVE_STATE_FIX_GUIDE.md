# Save State — Fix Guide

A walkthrough of exactly **where to look** and **what to change** to make saving/loading work.
Nothing in this doc changes code — it's the map. Line numbers are from the current
`polish-and-fixing_jacob` branch and may drift by a line or two as you edit.

---

## 0. The one thing to understand first: there are two brains

The whole save problem comes from state living in **two autoloads that never talk to each other**.

| Concept   | `Global` (overworld/save brain) — `assets/Scripts/Global.gd` | `GlobalCombatInformation` (combat brain) — `assets/Resources/Global_Combat_Information.gd` |
|-----------|--------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| Party     | `party_slot_1/2/3` (Dwarf/Mage/Paladin `.tres`)              | `active_party_slots` / `all_party_slots` (MC/Rowan/Lyra `.tres`)                            |
| Money     | `money`                                                      | `currency_held` (defaults to 200)                                                          |
| Inventory | `item_list` / `equipment_list` / `weapon_list`              | `all_held_items` / `all_held_equipment` / `all_held_weapons`                               |
| Serializer| `get_save_data()` (flat dict)                               | `export_to_JSON()` / `load_saved_data()`                                                    |

Autoload order (`project.godot`): `DialogueSystem, Fade, EnemyGeneticAlgorithm, GlobalCombatInformation, Global`.

**The save menu only knows about `Global`.** So every dungeon reward (coins, XP, bond levels,
loot, quests) lives in `GlobalCombatInformation` and is **silently thrown away** on save/load.
This is the #1 player-facing bug. Everything below is downstream of this split.

There are also **two save file systems**:
- **Live:** `save_load_menu.gd` → `user://saves/slot_N.json` (this is the one the UI uses).
- **Orphan/legacy:** `Global.gd`'s `save_game.dat` API (`load_save` / `load_save_data` /
  `get_save_data` / `create_save` / `save_state_to_slot`). Nothing *writes* it anymore, but
  `Global.load_save_data()` is still *read* on every scene load (see Fix 2).

---

## The save/load data flow today (annotated)

**Save** (`save_load_menu.gd:69 _save_to_slot`):
1. `Global.get_save_data()` (`Global.gd:306`) builds a flat dict — money, party slots, item/equip/weapon
   path lists, progression, and `player_position` from `get_first_node_in_group("Overworld_Player")`.
2. Playtime is tacked on (`save_load_menu.gd:72-74`).
3. Written to `user://saves/slot_N.json`, then `file.close()` (`:80`) — this part is fine.
   **Combat state is never touched.**

**Load** (`save_load_menu.gd:83 _load_from_slot` → `:94 _apply_save_data`):
1. Restores `Global.money`, party, inventory, progression.
2. If `player_position` exists → stashes it in `Global.saved_position` and sets
   `Global.loading_from_save = true` (`:125-127`).
3. `change_scene_to_file(location_paths.get(current_location, Hearthwynn))` (`:129`).
4. On the new scene, the **only** reader of `saved_position` / `loading_from_save` is
   `save_load_menu.gd:18-20` — which is a `Control` nested in the pause menu, so it sets *its own*
   `global_position` (wrong coordinate space) and clears the flag before the player ever sees it.

Result: **the saved position is never applied to the player**, and because `current_location` is
almost always stale (see Fix 1b), **load nearly always dumps you at Hearthwynn's default spawn.**

---

## Fix 1 — Make "save anywhere / load back there" actually work (highest value, low effort)

Two independent breakages combine here. Fix both.

### 1a. The position flag is consumed by the wrong node

- **Where it's set:** `save_load_menu.gd:125-127` (`_apply_save_data`).
- **Where it's wrongly consumed:** `save_load_menu.gd:18-20` (`_ready` of the pause-menu Control).
- **Where it *should* be consumed:** the actual player, in `scripts/player.gd:_ready()` (or in
  `EnvironmentHandler.teleport_player_to_spawn()`, `EnvironmentHandler.gd:12`).

**What to change (in words):**
1. Delete the `if Global.loading_from_save:` branch from `save_load_menu.gd:18-20`. The menu should
   just always do its normal setup (buttons, refresh). Right now that setup is stuck in the `else`.
2. In `scripts/player.gd:_ready()`, after `$Camera2D.reset_smoothing()`, add: if
   `Global.loading_from_save` is true, set `global_position = Global.saved_position`, then set
   `Global.loading_from_save = false`. The player is a `CharacterBody2D`, so this is the correct
   coordinate space.
3. Watch the ordering vs. `EnvironmentHandler`: `EnvironmentHandler._ready()` also moves the player
   (`teleport_player_to_spawn`, `:12-20`), but **only when `current_loading_zone != ""`**. On a
   fresh load `current_loading_zone` is `""`, so it early-returns and won't fight you. Just make sure
   you don't set a loading zone during load.

### 1b. `current_location` is never updated during normal play

- **Default:** `Global.gd:14` → `current_location = "[Forest Dungeon: Floor 1]"` — this is **not a key**
  in `location_paths` (`Global.gd:64-69`).
- **Only writers today:** load paths (`save_load_menu.gd:97`, `Global.gd:277`). Normal overworld
  travel sets `current_loading_zone` (`teleport_handler.gd:98`), **not** `current_location`.
- **Consequence:** `save_load_menu.gd:129` does `location_paths.get(current_location, Hearthwynn)` →
  the `.get` fallback fires almost every load → you always land in Hearthwynn.

**What to change (in words):**
- In `teleport_handler.gd:_on_area_2d_body_entered` (`:92-100`), when a real transition happens, set
  `Global.current_location = _target_region` right before/after `change_scene`. `_target_region` is
  already one of the `location_paths` keys ("Village"/"Forest"/"Cliff Side"/"Buildings_Insides"), so
  it will round-trip cleanly.
- Do the same on dungeon return (`dungeon_reward_screen.gd` → set `current_location` to "Village"
  when it sends you back).
- Change the default at `Global.gd:14` to a real key, e.g. `"Village"`, so a save taken before any
  transition still resolves.

**Test:** New game → walk to Forest → save → quit → load. You should reappear in Forest at your
saved coordinates, not Hearthwynn's spawn.

---

## Fix 2 — Stop reloading the disk on every scene change (trivial, kills 2 latent bugs)

- **Where:** `scripts/player.gd:19` → `Global.load_save_data()` inside `Player._ready()`. Since a
  player instance exists in every location scene, **this runs on every door transition.**
- It reads `user://save_game.dat` (`Global.gd:265 load_save_data` → `:254 load_save`), the orphaned
  legacy file.

**Two hazards it creates:**
1. If an old `save_game.dat` exists on disk from a previous build, **every transition overwrites your
   live in-memory money/party/progression/location with stale disk data.**
2. `load_save_data` accumulates without clearing: `Global.gd:289` clears `item_list`, but
   `:293-296` **append to `equipment_list` and `weapon_list` without clearing first** → equipment and
   weapons duplicate and grow every transition. (Compare `_apply_save_data`, `save_load_menu.gd:110-115`,
   which correctly clears all three.)

**What to change (in words):**
- Delete the `Global.load_save_data()` call from `scripts/player.gd:19`. Loading should only happen
  on an explicit slot-load through the menu. This single deletion removes the per-transition disk I/O,
  the accumulation bug, and the legacy-clobber risk.
- Optional cleanup: once nothing calls it, delete the orphaned `save_game.dat` API from `Global.gd`
  (`load_save`, `load_save_data`, `get_save_data`'s legacy usage stays — it's still used by the menu,
  `create_save`, `save_state_to_slot`, `SAVE_PATH`). Keep `get_save_data()`; it's the live serializer.

---

## Fix 3 — Persist `GlobalCombatInformation` in the save (the big one)

This is where dungeon loot / XP / bonds / quests currently vanish. The serializer already exists
(`export_to_JSON`, `load_saved_data`) — it's just never wired into a slot.

### Wiring

- **On save** (`save_load_menu.gd:_save_to_slot`, `:69`): after `Global.get_save_data()`, embed the
  combat state, e.g. `data["combat"] = <combat dict>`.
- **On load** (`save_load_menu.gd:_apply_save_data`, `:94`): after restoring `Global`, call
  `GlobalCombatInformation.load_saved_data(data["combat"])`.

### But `export_to_JSON` / `load_saved_data` have their own bugs — fix these too

Look at `assets/Resources/Global_Combat_Information.gd`:

1. **Double-stringify (`:157`).** `export_to_JSON()` ends with `JSON.stringify(ret_dict, "\t")` — it
   returns a **String**, not a Dictionary. If you assign that string into `data["combat"]` and then
   `JSON.stringify(data)` again in the save menu, you get an escaped string-in-string that
   `load_saved_data` can't read.
   **Change:** make it return the raw `ret_dict` (drop the inner `JSON.stringify`), OR keep it
   returning a string and `JSON.parse_string(...)` it back to a dict before embedding. Pick one and be
   consistent. Returning the dict is cleaner.

2. **`load_saved_data` appends onto an already-populated array (`:81-85`).** `_ready()` (`:33-35`)
   already fills `all_party_slots` with MC/Rowan/Lyra. `load_saved_data` then **appends** the saved
   members on top → duplicate party after load. Same pattern risk for `dungeon_types` (`:37-38` seeds
   two, `:102-105` appends more).
   **Change:** `.clear()` `all_party_slots`, `all_held_equipment`, `all_held_weapons`,
   `all_held_items`, `active_quests`, `completed_quests`, and `dungeon_types` at the top of
   `load_saved_data` before the loops.

3. **Quests and dungeon_types are serialized as raw Resource objects (`:138, :142, :146`).**
   `active_quest_slots[new_key] = active_quests[quest_]` stores the `quest` **object**, not a path or
   dict. `JSON.stringify` cannot serialize a Godot Resource — you'll get `{}` or an error. Meanwhile
   `load_saved_data` reads them back as `a_quest["path"]` (`:96-100`) — a mismatch that would crash.
   **Change:** serialize quests/dungeon_types the same way items/equipment do — as a dict containing at
   least `{"path": resource.resource_path, ...}` — so the `["path"]` reader on load matches.

4. **Active vs. all party.** `export_to_JSON` only serializes `all_party_slots` (`:119`), not
   `active_party_slots`. On load you restore `all_party_slots` but `active_party_slots` (what actually
   fights, `transition_to_dungeon:51`) is whatever `_ready()` seeded. Decide whether active party is
   derived from `all` on load, and restore/rebuild it explicitly.

**Test:** Run a dungeon → gain coins/XP/loot → return to village → save → load. Currency, party XP,
bond levels, and inventory should match what you had, not reset to defaults (200 currency, level 1).

---

## Fix 4 — `progression_state` key-type corruption (seals/quests don't round-trip)

- **Seeded with STRING keys:** `Global.gd:88-101` (`"SEAL_1": true`, `"QUEST_3": true`, ...).
- **Overwritten with INT keys:** `Global.gd:496-497` in `_ready()` →
  `for flag in Progression_Flags.values(): progression_state[flag] = false` (flag is an int enum).
  So after `_ready`, the dict holds **both** string keys and int keys.
- **Load collapses them:** `save_load_menu.gd:118-119` and `Global.gd:299-300` do
  `progression_state[int(key)] = ...`. `int("SEAL_1") == 0`, `int("QUEST_1") == 0`, etc. → every
  string-keyed flag collapses onto key `0`. Seals/quests do not survive a save/load.

**What to change (in words):**
- Pick **one** key convention end to end. Recommended: the int enum `Progression_Flags`
  (`Global.gd:38-51`) everywhere.
  - Replace the string-keyed literal at `Global.gd:88-101` with int keys (or just drop the literal and
    let the `_ready()` loop seed everything to `false`, then set the couple you want true by enum).
  - Since keys go through JSON (which stringifies dict keys to strings), the `int(key)` on load is
    correct **as long as the saved keys are the stringified ints** ("0".."11"), not "SEAL_1". Once the
    seed is int-keyed, `int(key)` round-trips correctly.
- Note `can_take_quest` (`Global.gd:519-526`) and `is_unlocked` (`:508`) already index by enum int —
  they're consistent with the int convention, which is another reason to standardize on int.

---

## Fix 5 — Reconcile money + party ownership (the root cause)

Even after Fixes 1–4, the two brains still disagree about who owns the wallet and the party:
shop purchases move `Global.money`; dungeon rewards move `GlobalCombatInformation.currency_held`
(`Global_Combat_Information.gd:73`).

**Decision to make (this is a design call, flag it to the other dev):** pick one canonical owner for
money and one for party, then bridge.

Cheapest viable approach — **one-way sync at scene boundaries:**
- On dungeon **enter** (`transition_to_dungeon`, `:47`): copy `Global.money → currency_held` and
  `Global` party → `active_party_slots` (or agree the combat brain reads from Global).
- On dungeon **exit** (`dungeon_reward_screen.gd` return to village): copy `currency_held → Global.money`
  and combat party stats back into `Global`.

Long-term the right fix is to **delete one of the two stores** and have everyone read the survivor,
but a boundary sync unblocks saving without a big refactor.

---

## Smaller fixes (do in a cleanup pass)

| # | Where | Problem | Change |
|---|-------|---------|--------|
| A | `scenes/main/player.tscn` (Player:135, CollisionShape2D:139, Area2D:158, Area2D/CollisionShape2D:161) | 4 nodes tagged `Overworld_Player` → `get_nodes_in_group` returns 4 ("duplicate player" red herring); `get_first_node_in_group` (`Global.gd:327`) relies on tree order | Keep the group only on the root `Player`; remove from the 3 children |
| B | `teleport_handler.gd:95-97` | First door in each new scene no-ops: player spawns on the destination zone, guard clears `current_loading_zone` and returns; but `EnvironmentHandler` never resets it, so the *next* real door hits the non-empty branch and returns | Reset `Global.current_loading_zone = ""` in `EnvironmentHandler.teleport_player_to_spawn` (`EnvironmentHandler.gd:12`) after positioning; drop the consume-on-entry hack |
| C | `Global_Combat_Information.gd:72` | `experience_gained / (active_party_slots.size() - 1)` → divide-by-zero if party size is 1 | Divide by `size()`, or guard `size() > 1` |
| D | `Global_Combat_Information.gd:68` | Drop check inverted: `if chance > drop_chance` drops when roll *exceeds* chance (0.9 chance → ~10% drops) | Use `<` |
| E | `teleport_handler.gd:100`, `dungeon_reward_screen.gd:47`, `Travel_to_dungeon.gd:66` | Bracket access `location_paths[key]` crashes on a bad key | Use `.get(key, fallback)` |
| F | `Global.gd:10` `entire_party` | Saved (`:309`) but never populated → always empty; implies state that isn't there | Remove from payload or actually populate |
| G | `EnvironmentHandler.gd:23-24` | Assumes `camera_bounds` child 0/1 are exactly the two markers | Look them up by name |
| H | `Fade.fade_in/out` (`fade_handler.gd:35,62`) | Early-returns when `is_fading` **without awaiting** → `await Fade.fade_in()` resumes instantly mid-fade during rapid transitions | Await the in-flight fade instead of returning immediately |
| I | Debug prints in hot paths: `scripts/player.gd:15-17`, `save_load_menu.gd:17`, `teleport_handler.gd:102-105`, `Global_Combat_Information.gd:43` | Noise / perf | Delete (the teleport one is already removed in your working tree) |
| J | Naming traps | `locations.Infirmay2` (`Global.gd:58`), `Cliff Siude.tscn`, `Buildings_Insides` key ↔ `Building Insides.tscn` file | Leave the *paths* alone (they work); just don't "fix" a filename without updating `location_paths` |
| K | Unclosed READ handles: `Global.gd:259`, `save_load_menu.gd:47,88`, `dialogue_system.gd:176` | GC-reliant, smell not crash | Add `file.close()` |
| L | Per-frame churn: `Global._physics_process:126` (cursor+clock every frame), `Travel_to_dungeon._physics_process:41-48` & `dungeon_reward_screen._physics_process:34-41` (new tween every cycle), `player.gd:37-40` (texture write every frame) | Perf | Make tweens single looping tweens in `_ready`; make texture writes event-driven off inventory changes |

---

## Suggested order of work

If time is short, do these three — they're where the two brains actively contradict each other and
where players lose progress:

1. **Fix 2** (delete `load_save_data()` from `Player._ready`) — one line, removes two bugs immediately.
2. **Fix 1** (position restore + maintain `current_location`) — makes save/load land you where you saved.
3. **Fix 3** (persist `GlobalCombatInformation`, plus its serializer bugs) — stops dungeon/party/quest
   progress from vanishing.

Then Fix 4 (progression keys), Fix 5 (money/party ownership — needs a design decision with your
teammate), then the cleanup table.

### End-to-end test checklist
- [ ] New game → move in overworld → save → load → same location + coordinates.
- [ ] Buy something (money changes) → save → load → money persists.
- [ ] Run a dungeon → gain coins/XP/loot → save → load → combat currency, party XP, bonds, loot persist.
- [ ] Set a seal/quest flag → save → load → flag still set (not collapsed to index 0).
- [ ] Transition through several doors in a row → no equipment/weapon duplication, first door in each
      scene works, no mid-fade teleport.
