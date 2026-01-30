# Sealbound — Getting Started (Godot 4.6 + Git LFS + Workflow)

Repo: `https://github.com/AlisaK13003/sealbound.git`
Godot version: **Godot 4.6 (stable)** ([Godot Engine][1])

Assumptions:

* You already have **Git** available on your machine.
* This project uses **Git LFS** (required for contributors).
* `.gitignore` and `.gitattributes` are already set up in the repo.

---

## 1) Download Godot 4.6

Get Godot 4.6 (stable) here: **[Godot 4.6 (stable) download](https://godotengine.org/download/archive/4.6-stable/)** ([Godot Engine][1])

Basic run notes:

* **Windows**: download → unzip → run `Godot_v4.6-stable_*.exe`
* **Linux**: download → extract → run the `Godot_v4.6-stable_*` binary (you may need `chmod +x <file>`)

---

## 2) One-time setup: enable Git LFS (required)

Run this once on your machine (any OS):

```bash
git lfs install
```

---

## 3) Download the project

### Linux (Terminal)

```bash
git clone https://github.com/AlisaK13003/sealbound.git
cd sealbound
git lfs pull
```

### Windows (PowerShell)

```powershell
git clone https://github.com/AlisaK13003/sealbound.git
cd sealbound
git lfs pull
```

Recommended on Windows (helps avoid noisy line-ending diffs):

```powershell
git config --global core.autocrlf input
```

---

## 4) Open the project in Godot

1. Launch **Godot 4.6**
2. In Project Manager: **Import** the cloned `sealbound/` folder
3. Open the project and run it (F5)

---

## 5) Development workflow (everyone can push branches)

### A) Start from an updated `main`

Do this before starting new work:

```bash
git checkout main
git pull --rebase
git lfs pull
```

### B) Create a branch for your task

Branch naming:

* `feature/<short-name>` (new feature)
* `fix/<short-name>` (bug fix)
* `chore/<short-name>` (cleanup/tooling)

```bash
git checkout -b feature/my-change
```

### C) Work → commit

Check what changed:

```bash
git status
git diff
```

Commit:

```bash
git add -A
git commit -m "Add <short description>"
```

### D) Push your branch

```bash
git push -u origin feature/my-change
```

### E) Open a Pull Request (recommended)

Even though everyone can push branches, PRs keep `main` stable and make reviews easy:

* PR from `feature/my-change` → `main`
* Include:

  * what changed
  * how to test it
  * screenshots/video if visuals changed

---

## 6) Keep your branch up to date

If `main` changes while you’re working:

```bash
git fetch origin
git rebase origin/main
git lfs pull
```

Then push your rebased branch:

```bash
git push --force-with-lease
```

---

## 7) Quick start (copy/paste)

```bash
git lfs install
git clone https://github.com/AlisaK13003/sealbound.git
cd sealbound
git lfs pull

git checkout main
git pull --rebase
git checkout -b feature/my-change
# make changes...
git add -A
git commit -m "Add my change"
git push -u origin feature/my-change
```

---
