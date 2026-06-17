#!/usr/bin/env bash
# Regression check: writing-plans hands off to inline executing-plans, no execution options.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/writing-plans/SKILL.md"
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

echo "=== Writing Plans Inline Execution Test ==="
echo ""

assert_contains "invoke executing-plans inline" "handoff invokes executing-plans inline"
assert_contains "Do not offer execution choices" "handoff forbids choices"
assert_contains "REQUIRED SUB-SKILL:** Use superpowers:executing-plans" "executing-plans is required"
assert_not_contains "Two execution options" "old two-option prompt removed"
assert_not_contains "superpowers:subagent-driven-development" "writing-plans no longer points at subagent execution"
assert_not_contains "Subagent-Driven chosen" "subagent choice branch removed"
assert_not_contains "Inline Execution chosen" "inline choice branch removed"

if grep -Fq '"test-writing-plans-inline-execution.sh"' "$RUNNER"; then
    echo "  [PASS] regression runs in default fast suite"
else
    echo "  [FAIL] regression runs in default fast suite"
    failures=$((failures + 1))
fi

if grep -Fq "test-writing-plans-inline-execution.sh" "$README"; then
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
