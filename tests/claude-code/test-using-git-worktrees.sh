#!/usr/bin/env bash
# Test: using-git-worktrees skill
# Verifies that code-changing work uses worktrees by default.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: using-git-worktrees skill ==="
echo ""

echo "Test 1: Code-changing worktree default..."

output=$(run_claude "In a git repository, should an agent use the using-git-worktrees skill before fixing a small bug or editing code? Mention any exception." 30)

if assert_contains "$output" "using-git-worktrees\|worktree" "Mentions worktree for code changes"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "unless.*user\|explicit.*user\|opts out\|says not\|read-only" "Mentions explicit override or read-only exception"; then
    : # pass
else
    exit 1
fi

echo ""

echo "Test 2: Read-only worktree exception..."

output=$(run_claude "Do read-only tasks like code review, explanation, search, or planning require creating a git worktree?" 30)

if assert_contains "$output" "read-only\|review\|explanation\|search\|planning" "Recognizes read-only tasks"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "do not\|don't\|not require\|no worktree" "Does not require worktree for read-only tasks"; then
    : # pass
else
    exit 1
fi

echo ""

echo "Test 3: Feature completion merges worktree branch..."

output=$(run_claude "After completing and verifying a feature in a git worktree, what should an agent do with the worktree branch?" 30)

if assert_contains "$output" "merge\|merged" "Mentions merging completed feature work"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "base branch\|main\|master\|finishing-a-development-branch" "Mentions base branch or finishing workflow"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All using-git-worktrees skill tests passed ==="
