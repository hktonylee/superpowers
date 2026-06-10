#!/usr/bin/env bash
# Regression check: new specs and implementation plans use short docs paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BRAINSTORMING_SKILL="$REPO_ROOT/skills/brainstorming/SKILL.md"
WRITING_PLANS_SKILL="$REPO_ROOT/skills/writing-plans/SKILL.md"
HELPERS="$REPO_ROOT/tests/claude-code/test-helpers.sh"
EXPLICIT_PROMPTS_DIR="$REPO_ROOT/tests/explicit-skill-requests/prompts"

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

assert_not_contains() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if grep -Fq "$pattern" "$file"; then
        echo "  [FAIL] $label"
        echo "    Did not expect to find: $pattern"
        echo "    In file: $file"
        failures=$((failures + 1))
    else
        echo "  [PASS] $label"
    fi
}

echo "=== Doc Artifact Paths Test ==="
echo ""

assert_contains "$BRAINSTORMING_SKILL" 'docs/specs/YYYY-MM-DD-<topic>-design.md' "brainstorming uses docs/specs for new specs"
assert_not_contains "$BRAINSTORMING_SKILL" 'docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md' "brainstorming does not default new specs under docs/superpowers"

assert_contains "$WRITING_PLANS_SKILL" 'docs/plans/YYYY-MM-DD-<feature-name>.md' "writing-plans uses docs/plans for new plans"
assert_not_contains "$WRITING_PLANS_SKILL" 'docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md' "writing-plans does not default new plans under docs/superpowers"

assert_contains "$HELPERS" 'docs/plans/$plan_name.md' "test helper creates plans under docs/plans"

if grep -R "docs/superpowers/plans/auth-system.md" "$EXPLICIT_PROMPTS_DIR" >/dev/null; then
    echo "  [FAIL] explicit skill prompts still reference docs/superpowers/plans/auth-system.md"
    failures=$((failures + 1))
else
    echo "  [PASS] explicit skill prompts use short docs/plans path"
fi

echo ""

if [ "$failures" -gt 0 ]; then
    echo "STATUS: FAILED ($failures failures)"
    exit 1
fi

echo "STATUS: PASSED"
