#!/bin/sh
# Lightweight secret scan. Used by the pre-commit hook (staged files) and runnable
# by hand over the whole tree:  scripts/check-secrets.sh --all
# Not a replacement for gitleaks/trufflehog, but catches the obvious stuff.
set -eu

cd "$(git rev-parse --show-toplevel)"

if [ "${1:-}" = "--all" ]; then
    files=$(git ls-files --cached --others --exclude-standard)
else
    files=$(git diff --cached --name-only --diff-filter=ACM)
fi
[ -n "$files" ] || exit 0

# Name patterns that should never be committed.
bad_names=$(printf '%s\n' "$files" | grep -E '(^|/)(\.env(\..*)?|env|local\.bash|id_(rsa|ed25519|ecdsa)[^/]*|.*\.(pem|key|p12|pfx)|\.netrc)$' \
    | grep -vE '\.example$' || true)

# Content patterns: well-known token shapes and generic key=value assignments.
pattern='(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{50,}|gh[ousr]_[A-Za-z0-9]{36,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{32,}|sk-ant-[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(password|passwd|secret|token|api[_-]?key)[A-Za-z0-9_]*[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9/+=_-]{16,})'

hits=
for f in $files; do
    [ -f "$f" ] || continue
    [ "$f" = "scripts/check-secrets.sh" ] && continue
    if [ "${1:-}" = "--all" ]; then
        grep -InE -e "$pattern" "$f" >/dev/null 2>&1 && hits="$hits $f"
    else
        git show ":$f" 2>/dev/null | grep -InE -e "$pattern" >/dev/null 2>&1 && hits="$hits $f"
    fi
done

fail=0
if [ -n "$bad_names" ]; then
    echo "check-secrets: refusing to commit files that look private:" >&2
    printf '  %s\n' $bad_names >&2
    fail=1
fi
if [ -n "$hits" ]; then
    echo "check-secrets: possible secrets in:" >&2
    printf '  %s\n' $hits >&2
    fail=1
fi
[ "$fail" -eq 0 ] || { echo "If this is a false positive, commit with --no-verify after double-checking." >&2; exit 1; }
echo "check-secrets: clean"
