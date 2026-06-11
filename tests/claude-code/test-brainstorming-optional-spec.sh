#!/usr/bin/env bash
# Regression check: approved simple designs may skip written specs and plans.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/brainstorming/SKILL.md"
RUNNER="$REPO_ROOT/tests/claude-code/run-skill-tests.sh"
README="$REPO_ROOT/tests/claude-code/README.md"

failures=0

assert_contains() {
    local pattern="$1"
    local label="$2"

    if grep -Fq "$pattern" "$SKILL"; then
        echo "  [PASS] $label"
    else
        echo "  [FAIL] $label"
        echo "    Expected to find: $pattern"
        failures=$((failures + 1))
    fi
}

assert_not_contains() {
    local pattern="$1"
    local label="$2"

    if grep -Fq "$pattern" "$SKILL"; then
        echo "  [FAIL] $label"
        echo "    Did not expect to find: $pattern"
        failures=$((failures + 1))
    else
        echo "  [PASS] $label"
    fi
}

echo "=== Brainstorming Optional Spec Test ==="
echo ""

assert_contains "All simple-task criteria must be true" "simple path has explicit criteria"
assert_contains "Skip the written spec and implementation plan" "simple path skips artifacts"
assert_contains "Invoke the relevant implementation skill directly" "simple path transitions directly"
assert_contains "If any criterion is false or uncertain, use the full spec path." "uncertain tasks use full path"
assert_not_contains "**The terminal state is invoking writing-plans.**" "writing-plans is not unconditional"

if grep -Fq '"test-brainstorming-optional-spec.sh"' "$RUNNER"; then
    echo "  [PASS] regression runs in default fast suite"
else
    echo "  [FAIL] regression runs in default fast suite"
    failures=$((failures + 1))
fi

if grep -Fq "test-brainstorming-optional-spec.sh" "$README"; then
    echo "  [PASS] regression is documented"
else
    echo "  [FAIL] regression is documented"
    failures=$((failures + 1))
fi

echo ""

if [ "$failures" -gt 0 ]; then
    echo "STATUS: FAILED ($failures failures)"
    exit 1
fi

echo "STATUS: PASSED"
