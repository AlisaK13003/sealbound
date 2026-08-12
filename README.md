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

My work focused on gameplay systems, UI flow, and making the project easier for a team to build on:

- Implemented configurable keyboard/controller bindings with saved settings and default bindings for exported builds.
- Built settings flows for video, audio, and key configuration from the title screen and in-game menus.
- Worked on player movement, pause/menu behavior, and input mapping across keyboard and controller.
- Developed RPG systems around NPC bonds, party progression, quests, and dungeon entry flow.
- Integrated story/cutscene support with dialogue, NPC state restoration, and scene transitions.
- Helped maintain the Git workflow, Git LFS asset setup, and repo structure for a multi-person Godot project.

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
