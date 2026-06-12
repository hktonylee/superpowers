#!/usr/bin/env bash
# Regression check: brainstorming must not offer the visual companion by default.

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

echo "=== Brainstorming Visual Companion Opt-In Test ==="
echo ""

assert_contains "Visual companion is opt-in only" "explicit opt-in policy is documented"
assert_contains "only when the user explicitly asks for it" "explicit user request is required"
assert_contains "Do not offer it, suggest it, or ask whether they want to use it." "no-offer rule is documented"
assert_contains "If the user explicitly asks for visual companion support" "explicit request still loads detailed guide"
assert_contains 'skills/brainstorming/visual-companion.md' "detailed guide remains reachable"

assert_not_contains "**Offer visual companion**" "checklist no longer includes offer step"
assert_not_contains "Visual questions ahead?" "flow no longer branches on visual questions"
assert_not_contains "Offer Visual Companion" "flow no longer contains offer node"
assert_not_contains "Want to try it?" "skill no longer prompts users to try companion"
assert_not_contains "If they agree to the companion" "skill no longer asks for companion consent"

if grep -Fq '"test-brainstorming-visual-companion-opt-in.sh"' "$RUNNER"; then
    echo "  [PASS] regression runs in default fast suite"
else
    echo "  [FAIL] regression runs in default fast suite"
    failures=$((failures + 1))
fi

if grep -Fq "test-brainstorming-visual-companion-opt-in.sh" "$README"; then
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
