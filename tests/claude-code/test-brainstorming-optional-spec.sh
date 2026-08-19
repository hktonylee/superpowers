#!/usr/bin/env bash
# Regression check: resolved designs continue without routine approval gates.

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
assert_contains "Only pause when multiple viable alternatives remain" "only unresolved alternatives require user choice"
assert_contains "Continue without asking for approval" "resolved design continues automatically"
assert_contains "Invoke writing-plans immediately after self-review" "reviewed spec transitions automatically"
assert_contains "multiple viable approaches would materially change the result" "alternative gate requires material impact"
assert_contains '"Multiple material\nalternatives?"' "flow applies material threshold"
assert_contains "Do not manufacture alternatives" "dominated alternatives do not create a gate"
assert_contains "If multiple material interpretations remain, return to the alternatives step" "self-review routes material ambiguity to user choice"
assert_contains '"Spec reveals material\nalternatives?"' "flow checks material alternatives after self-review"
assert_contains '"Spec reveals material\nalternatives?" -> "Present 2-3 alternatives" [label="yes"]' "flow returns review-time alternatives to user choice"
assert_contains '"Spec reveals material\nalternatives?" -> "Invoke writing-plans skill" [label="no"]' "flow advances reviewed spec without material alternatives"
assert_contains "continue automatically when no material alternatives remain" "checklist advances when material choices are resolved"
assert_not_contains "user has approved it" "hard gate does not require routine approval"
assert_not_contains "User Review Gate" "written spec has no user review gate"
assert_not_contains "User approves design?" "flow has no routine design approval branch"
assert_not_contains "User reviews spec?" "flow has no routine spec approval branch"
assert_not_contains "If so, pick one and make it explicit." "self-review does not silently choose material interpretation"
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
