# Sealbound

2D narrative fantasy RPG built by a five-person team.

**Godot · GDScript · Git LFS · Team Development**

## Media

<!-- Add a gameplay screenshot or GIF here. -->
<!-- Example: ![Sealbound gameplay](docs/media/sealbound-gameplay.gif) -->

## Overview

Sealbound is a story-driven fantasy RPG about exploring a coastal village, forming bonds with party members, taking on quests, and entering dungeons tied to the game's central mystery.

Players can:

- Explore 2D overworld areas with day/time progression.
- Talk to NPCs through branching dialogue and bond-driven interactions.
- Recruit and manage party members.
- Accept quests that connect village story moments to dungeon objectives.
- Enter dungeon areas with encounters, rewards, and party-based combat.

## My Contributions

My work focused on extending core RPG systems, narrative tooling, and keeping the team scoped and organized:

- Built and iterated on the dialogue system, including dialogue UI, portraits, branching choices, typewriter behavior, punctuation pauses, and story-gated dialogue flow.
- Added the NPC bond dialogue layer, connecting bond values, daily talk rewards, relationship tiers, and dialogue context to NPC interactions.
- Built on the existing NPC schedule system by adding schedule data, route/path support, interior schedules, and fixes for characters like Lyra, Sera, Orion, Rowan, Kaela, and Cassian.
- Expanded shop and menu flows, including apothecary setup, shop modal behavior, owner details, pause/load menu integration, and title-screen settings/menu polish.
- Polished story and demo flow through cutscenes, scene transitions, quest-board setup, Lyra axe quest progression, debug skips, and NPC restoration after cutscenes.
- Implemented and maintained input/keybind work, including exported-build default key configs so players can move and interact without manual setup.
- Supported project management for the five-person team by managing scope, organizing priorities, and delegating tasks across systems, content, and polish work.

## Technical Highlights

### Input and Settings

Sealbound uses a custom settings manager that persists player preferences to `user://settings.cfg`. Keybinds are synced with Godot's `InputMap`, support keyboard/controller inputs, and now seed default bindings automatically so exported builds are playable immediately.

### Narrative and NPC Systems

NPCs support schedule-aware behavior, dialogue choices, bond tiers, daily bond rewards, and story actions such as starting quests or triggering cutscenes. Dialogue context can change based on relationship state and progression flags.

### Dungeon and Quest Flow

Dungeon travel connects quest state, unlock rules, selected dungeon data, party state, rewards, and combat transitions. Quest objectives can track items, enemy drops, and special dungeon requirements.

### Team Workflow

The project uses Git LFS for large assets and a branch-based workflow for features, fixes, and content updates. The repo includes Godot import metadata so team members can clone, pull LFS assets, and open the project consistently.

## Built With

- Godot 4.7
- GDScript
- Git LFS

## Installation

Install Git LFS once:

```bash
git lfs install
```

Clone the project:

```bash
git clone https://github.com/AlisaK13003/sealbound.git
cd sealbound
git lfs pull
```

Open in Godot:

1. Launch Godot 4.7.
2. Import the cloned `sealbound` folder.
3. Open the project.
4. Press `F5` to run.

## Default Controls

- Move: `WASD` or arrow keys
- Confirm / interact: `C` or Enter
- Cancel: `X`
- Pause: Escape
- Dungeon item: `P`
- Dungeon skill: `O`
