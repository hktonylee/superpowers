#!/usr/bin/env bash
# Regression check: commit guidance distinguishes verified completion work from
# honest exploratory checkpoints.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SUPERPOWERS_SKILL="$REPO_ROOT/skills/using-superpowers/SKILL.md"
EXECUTING_SKILL="$REPO_ROOT/skills/executing-plans/SKILL.md"
DEBUGGING_SKILL="$REPO_ROOT/skills/systematic-debugging/SKILL.md"
VERIFY_SKILL="$REPO_ROOT/skills/verification-before-completion/SKILL.md"
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

echo "=== Commit Verification Policy Test ==="
echo ""

assert_contains "$SUPERPOWERS_SKILL" "After a feature or fix is complete and verification passes, commit the work immediately unless the user explicitly says not to commit yet." "using-superpowers requires commits for verified complete work"
assert_contains "$SUPERPOWERS_SKILL" "Exploratory commits must describe the current status honestly" "using-superpowers requires truthful exploratory commits"
assert_contains "$SUPERPOWERS_SKILL" 'exclude build artifacts such as `dist/` and generated JavaScript emitted from TypeScript sources' "using-superpowers excludes generated Node artifacts"
assert_contains "$EXECUTING_SKILL" "commit at each meaningful checkpoint" "executing-plans commits meaningful checkpoints"
assert_contains "$DEBUGGING_SKILL" "commit the checkpoint anyway if it preserves useful progress" "systematic-debugging permits truthful exploratory checkpoints"
assert_contains "$VERIFY_SKILL" "Exploratory checkpoint commits are allowed without completion-level verification" "verification skill distinguishes exploratory checkpoints"
assert_contains "$README" "Verified feature work should be committed immediately unless the user explicitly says not to commit yet." "README documents commit policy"

echo ""

if [ "$failures" -gt 0 ]; then
    echo "STATUS: FAILED ($failures failures)"
    exit 1
fi

echo "STATUS: PASSED"
