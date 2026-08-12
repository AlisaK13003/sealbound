# Sealbound

Sealbound is a Godot fantasy RPG project with overworld exploration, party-based combat, dungeon content, NPC bonds, quests, and story cutscenes.

## Current Engine

- Godot 4.7 stable
- Git LFS is required for assets

## Getting Started

Install Git LFS once on your machine:

```bash
git lfs install
```

Clone the project and pull large assets:

```bash
git clone https://github.com/AlisaK13003/sealbound.git
cd sealbound
git lfs pull
```

Open the project in Godot:

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

Keybinds can be changed in the in-game settings menu. Fresh installs ship with default bindings, so players should not need to configure controls before playing.

## Development Workflow

Start new work from an updated `main`:

```bash
git checkout main
git pull --rebase
git lfs pull
```

Create a task branch:

```bash
git checkout -b feature/my-change
```

Before committing:

```bash
git status
git diff
```

Commit and push:

```bash
git add -A
git commit -m "Add my change"
git push -u origin feature/my-change
```

Use pull requests for changes that touch gameplay systems, scenes, assets, or shared resources.

## Repo Hygiene

Do not commit:

- `.godot/`
- OS files like `.DS_Store`
- temporary `*.tmp` or `*.TMP` files
- editor lock/backup files beginning with `~`

Keep generated exports outside the repository unless they are intentionally being published as release artifacts.
