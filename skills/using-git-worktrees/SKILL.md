---
name: using-git-worktrees
description: Use before code-changing work in a git repository, unless the user explicitly says not to use a worktree or the task is read-only - ensures an isolated workspace exists via native tools or git worktree fallback
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

Use this skill before making code or documentation changes in a git repository. This includes feature work, bug fixes, refactors, tests, generated assets, skill updates, and implementation-plan execution.

Read-only tasks do not require a worktree. Examples: code review, explanation, search, status checks, or planning that does not edit files. If the user explicitly asks to work in the current checkout or says not to use a worktree, follow that instruction.

Treat every follow-up code-changing request after a worktree is merged as new worktree work. Create a fresh worktree from the updated base branch, or reuse an existing active worktree only when it still exists and clearly matches the follow-up. Do not continue by editing the base checkout just because the previous worktree was integrated.

Before editing in a normal repo checkout, check whether the checkout has tracked changes:

```bash
git status --porcelain --untracked-files=no
```

If this command prints anything, create a worktree from the current committed `HEAD`. Uncommitted changes stay in the original checkout and are intentionally not copied into the new worktree. Untracked files alone do not count as a dirty checkout for this rule.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 3 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout. Continue only if the task will change code or docs, or the user explicitly requested isolation.

Do not stop to ask the user whether they want a worktree. Invoking this skill for code-changing work is the request for isolation. If the user has already declared in their instructions that they prefer to work in place, honor that and skip to Step 3. Otherwise, create the worktree.

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 3.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.

2. **Check for an existing project-local worktree directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, use it. If both exist, `.worktrees` wins.

3. **Check for an existing global directory:**
   ```bash
   project=$(basename "$(git rev-parse --show-toplevel)")
   ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
   ```
   If found, use it (backward compatibility with legacy global path).

4. **If there is no other guidance available**, default to `.worktrees/` at the project root.

#### Safety Verification (project-local directories only)

**MUST verify directory is ignored before creating worktree:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:** Add to .gitignore, commit the change, then proceed.

**Why critical:** Prevents accidentally committing worktree contents to repository.

Global directories (`~/.config/superpowers/worktrees/`) need no verification.

#### Create the Worktree

```bash
project=$(basename "$(git rev-parse --show-toplevel)")

# Determine path based on chosen location
# For project-local: path="$LOCATION/$BRANCH_NAME"
# For global: path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"

# Capture the base commit explicitly. This is the committed HEAD, not dirty working-tree state.
base_commit=$(git rev-parse HEAD)

git worktree add "$path" -b "$BRANCH_NAME" "$base_commit"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

## Step 3: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 4: Verify Clean Baseline

Run tests to ensure workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Completing Feature Work

After implementing, verifying, and committing a feature in a worktree, use `finishing-a-development-branch` to choose what happens next.

Default completed feature work to local integration unless the user explicitly wants a PR, wants to keep the branch, or wants to discard it. Rebase the feature branch before merging into the base branch. Resolve integration conflicts in the worktree branch first, then fast-forward the base branch, verify the result, remove the worktree, and delete the branch.

Do not leave a completed feature stranded in a worktree by default.

If the user immediately asks for a follow-up code-changing request after a worktree is merged, start this skill again. Reuse a preserved worktree only when the follow-up belongs on that same branch; otherwise create a new worktree from the updated base branch.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Global path exists | Use it (backward compat) |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Original checkout has tracked changes | Create worktree from committed `HEAD`; leave uncommitted changes in original checkout |
| Original checkout only has untracked files | Worktree not required by dirty-checkout rule |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |
| Feature complete and verified | Use `finishing-a-development-branch` to rebase, PR, keep, or discard |
| Follow-up code change after integrated worktree | Create new worktree from updated base, or reuse clearly matching active worktree |
| User explicitly says no worktree | Work in current checkout |
| Read-only task | Do not create a worktree |

## Common Mistakes

### Fighting the harness

- **Problem:** Using `git worktree add` when the platform already provides isolation
- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.

### Skipping detection

- **Problem:** Creating a nested worktree inside an existing one
- **Fix:** Always run Step 0 before creating anything

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: existing > global legacy > instruction file > default

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

### Treating tracked dirty changes as a blocker

- **Problem:** Work stalls even though a worktree can safely start from committed `HEAD`
- **Fix:** If `git status --porcelain --untracked-files=no` prints anything, create the worktree from `git rev-parse HEAD`; leave uncommitted changes in the original checkout

## Red Flags

**Never:**
- Create a worktree when Step 0 detects existing isolation
- Use `git worktree add` when you have a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if you have it, use it.
- Skip Step 1a by jumping straight to Step 1b's git commands
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking
- Start code-changing work in the original checkout unless the user explicitly requested it
- Treat untracked files alone as a dirty checkout
- Work around tracked dirty changes by making small edits in the original checkout
- Leave completed, verified feature work unintegrated in a worktree unless the user chose PR or keep-as-is
- Edit the base checkout for a follow-up code change just because the previous worktree was integrated

**Always:**
- Run Step 0 detection first
- Prefer native tools over git fallback
- Follow directory priority: existing > global legacy > instruction file > default
- Verify directory is ignored for project-local
- Check dirty state with `git status --porcelain --untracked-files=no` before editing in a normal repo checkout
- Auto-detect and run project setup
- Verify clean test baseline
- Use `finishing-a-development-branch` to dispose of completed feature work
- Restart worktree setup for follow-up code changes after integration; reuse only a matching active worktree
