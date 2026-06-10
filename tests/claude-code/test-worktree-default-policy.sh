#!/usr/bin/env bash
# Regression check: code-changing git work should default to an isolated
# worktree, and completed worktree branches should have an explicit finish path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

USING_SKILL="$REPO_ROOT/skills/using-git-worktrees/SKILL.md"
SUPERPOWERS_SKILL="$REPO_ROOT/skills/using-superpowers/SKILL.md"
FINISHING_SKILL="$REPO_ROOT/skills/finishing-a-development-branch/SKILL.md"
README="$REPO_ROOT/README.md"

failures=0

assert_contains() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if grep -Fq "$pattern" "$file"; then
        echo "  [PASS] $label"
    else
        echo "  [FAIL] $label"
        echo "    Expected to find: $pattern"
        echo "    In file: $file"
        failures=$((failures + 1))
    fi
}

echo "=== Worktree Default Policy Test ==="
echo ""

assert_contains "$USING_SKILL" "Use this skill before making code or documentation changes in a git repository." "using-git-worktrees applies to code and docs changes"
assert_contains "$USING_SKILL" "Read-only tasks do not require a worktree." "using-git-worktrees documents read-only exception"
assert_contains "$USING_SKILL" "Do not stop to ask the user whether they want a worktree." "using-git-worktrees treats skill invocation as authorization"
assert_contains "$USING_SKILL" "tracked changes" "using-git-worktrees handles dirty tracked check"
assert_contains "$USING_SKILL" "Do not leave a completed feature stranded in a worktree by default." "using-git-worktrees requires completed work disposal"
assert_contains "$USING_SKILL" "follow-up code-changing request after a worktree is merged" "using-git-worktrees covers follow-up requests"

assert_contains "$SUPERPOWERS_SKILL" 'For code-changing tasks in a git repository, invoke `using-git-worktrees` before editing files.' "using-superpowers routes code changes through worktrees"
assert_contains "$FINISHING_SKILL" "Rebase the feature branch before merging into the base branch." "finishing skill rebases before merge"
assert_contains "$README" "Code-changing work in a git repository starts in a worktree by default." "README documents worktree default"

echo ""

if [ "$failures" -gt 0 ]; then
    echo "STATUS: FAILED ($failures failures)"
    exit 1
fi

echo "STATUS: PASSED"
