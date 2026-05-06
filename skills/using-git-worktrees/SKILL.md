---
name: "using-git-worktrees"
description: "Use before any code-changing work in a git repository, unless the user explicitly says not to use a worktree or the task is read-only - creates isolated git worktrees with smart directory selection and safety verification"
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

Use this skill before making code or documentation changes in a git repository. This includes feature work, bug fixes, refactors, tests, generated assets, skill updates, and implementation-plan execution.

Do not require a worktree for read-only tasks such as code review, explanation, search, status checks, or planning that does not edit files. If the user explicitly asks to work in the current checkout or says not to use a worktree, follow that instruction.

Before editing, check whether the current checkout has tracked changes:

```bash
git status --porcelain --untracked-files=no
```

If this command prints anything, create a worktree no matter how small the requested change is. This prevents multiple Codex sessions from editing over each other. Untracked files alone do not count as a dirty checkout for this rule.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Directory Selection Process

Default to a project-local `.worktrees/` directory unless the repository already defines a different convention.

Follow this priority order:

### 1. Check Existing Directories

```bash
# Check in priority order
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```

**If found:** Use that directory. If both exist, `.worktrees` wins.

### 2. Check CLAUDE.md / Repo Instructions

```bash
grep -i "worktree.*director" CLAUDE.md AGENTS.md 2>/dev/null
```

**If preference specified:** Use it without asking.

### 3. Create `.worktrees/`

If no directory exists and no repo instruction specifies otherwise:

```bash
mkdir -p .worktrees
```

Use `.worktrees/` without asking. Only ask the user if `.worktrees/` cannot be used safely.

## Safety Verification

### For Project-Local Directories (.worktrees or worktrees)

**MUST verify directory is ignored before creating worktree:**

```bash
# Check if directory is ignored (respects local, global, and system gitignore)
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:**

Per Jesse's rule "Fix broken things immediately":
1. Add appropriate line to .gitignore
2. Commit the change
3. Proceed with worktree creation

**Why critical:** Prevents accidentally committing worktree contents to repository.

### For Global Directory (~/.config/superpowers/worktrees)

No .gitignore verification needed - outside project entirely.

## Creation Steps

### 1. Detect Project Name

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### 2. Create Worktree

Create the new worktree from the repository's current `HEAD` commit. A dirty original checkout is allowed and should not block worktree creation; uncommitted changes stay in the original checkout and are intentionally not copied into the new worktree.

If `git status --porcelain --untracked-files=no` shows tracked modifications, additions, deletions, renames, or staged changes in the original checkout, creating a worktree is mandatory even for one-line edits or tiny commits.

```bash
# Capture the base commit explicitly. This is the committed HEAD, not dirty working-tree state.
base_commit=$(git rev-parse HEAD)

# Determine full path
case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  ~/.config/superpowers/worktrees/*)
    path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
    ;;
esac

# Create worktree with new branch
git worktree add "$path" -b "$BRANCH_NAME" "$base_commit"
cd "$path"
```

### 3. Run Project Setup

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

### 4. Verify Clean Baseline

Run tests to ensure worktree starts clean:

```bash
# Examples - use project-appropriate command
npm test
cargo test
pytest
go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### 5. Report Location

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Completing Feature Work

After implementing, verifying, and committing a feature in a worktree, rebase the feature branch back into the base branch unless the user explicitly asks to keep the branch separate or open a PR instead.

Use `superpowers:finishing-a-development-branch` for this completion step. Its local rebase workflow updates the base branch, rebases the feature branch inside the worktree before any merge, resolves conflicts there, fast-forwards the base branch, verifies the result, deletes the feature branch, and removes the worktree.

Do not leave a completed feature stranded in a worktree by default.

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check repo instructions → create `.worktrees/` |
| Directory not ignored | Add to .gitignore + commit |
| Original checkout has tracked dirty changes | Must create worktree from current `HEAD`; do not copy uncommitted changes |
| Original checkout only has untracked files | Worktree not required by dirty-checkout rule |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |
| Feature complete and verified | Rebase feature branch inside the worktree before merging via `finishing-a-development-branch` |
| User explicitly says no worktree | Work in current checkout |
| Read-only task | Do not create a worktree |

## Common Mistakes

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Assuming a non-local directory

- **Problem:** Creates inconsistency and unnecessary sprawl when the repo has no preference
- **Fix:** Follow priority: existing > repo instructions > `.worktrees/`

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

### Hardcoding setup commands

- **Problem:** Breaks on projects using different tools
- **Fix:** Auto-detect from project files (package.json, etc.)

### Treating tracked dirty changes as a blocker

- **Problem:** Work stalls even though a worktree can safely start from committed `HEAD`
- **Fix:** If `git status --porcelain --untracked-files=no` prints anything, create the worktree from `git rev-parse HEAD`; leave uncommitted changes in the original checkout

## Example Workflow

```
You: I'm using the using-git-worktrees skill to set up an isolated workspace.

[Check .worktrees/ - exists]
[Verify ignored - git check-ignore confirms .worktrees/ is ignored]
[Create worktree: git worktree add .worktrees/auth -b feature/auth]
[Run npm install]
[Run npm test - 47 passing]

Worktree ready at /Users/jesse/myproject/.worktrees/auth
Tests passing (47 tests, 0 failures)
Ready to implement auth feature
```

## Red Flags

**Never:**
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking
- Assume a global directory when the repo has no preference
- Skip repo instruction check
- Start code-changing work in the original checkout unless the user explicitly requested it
- Treat untracked files alone as a dirty checkout
- Work around tracked dirty changes by making "small" edits in the original checkout
- Refuse to create a worktree only because the original checkout has tracked uncommitted changes
- Merge a completed worktree into the base branch before rebasing it inside the worktree
- Leave completed, verified feature work unintegrated in a worktree unless the user chose PR or keep-as-is

**Always:**
- Follow directory priority: existing > repo instructions > `.worktrees/`
- Verify directory is ignored for project-local
- Check dirty state with `git status --porcelain --untracked-files=no`
- Create worktrees from the current `HEAD` commit when the original checkout has tracked dirty changes
- Auto-detect and run project setup
- Verify clean test baseline
- Rebase completed feature branches inside their worktrees before merging them
- Use `finishing-a-development-branch` to rebase or otherwise explicitly dispose of completed feature work

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- **subagent-driven-development** - REQUIRED before executing any tasks
- **executing-plans** - REQUIRED before executing any tasks
- Any skill needing isolated workspace
- Any code-changing task in a git repository unless explicitly overridden by the user

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
