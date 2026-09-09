#!/bin/sh

set -eu

REPOSITORY_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$REPOSITORY_DIR"

# Only parse source and built scripts. The functional subcommands are never run.
sh -n src/codex.sh
sh -n src/omcli.sh
sh -n bin/omcli

expected_version="$(tr -d '\n' < VERSION)"
[ "$expected_version" = "2026.09.09.1" ]
grep -F 'PROGRAM_VERSION="@VERSION@"' src/codex.sh >/dev/null
grep -F 'OMCLI_VERSION="@VERSION@"' src/omcli.sh >/dev/null
if grep -F '@VERSION@' bin/omcli >/dev/null; then
  echo "unexpanded version placeholder" >&2
  exit 1
fi

# Source-only mode prevents dispatch. All external execution is replaced before
# any router behavior is exercised, so this test cannot reach the real helpers.
OMCLI_SOURCE_ONLY=1
export OMCLI_SOURCE_ONLY
. ./bin/omcli

[ "$(omcli_main --version)" = "omcli $expected_version" ]
help_output="$(omcli_main)"
for command_name in lockscreen ncdu codex; do
  printf '%s\n' "$help_output" | grep -F "$command_name" >/dev/null
done

omcli_external() {
  for argument in "$@"; do printf '%s\n' "$argument"; done
}
omcli_run() {
  for argument in "$@"; do printf '%s\n' "$argument"; done
}
omcli_lockscreen_path() { printf '/mock/omcli-lockscreen\n'; }
omcli_helper_is_executable() { [ "$1" = /mock/omcli-lockscreen ]; }
lock_output="$(omcli_main lockscreen)"
[ "$lock_output" = "/mock/omcli-lockscreen" ]

omcli_has_ncdu() { return 0; }
omcli_epoch() { printf '1234567890\n'; }
HOME=/mock/home
export HOME
ncdu_output="$(omcli_main ncdu)"
expected_ncdu_output="$(printf '%s\n' \
  ncdu -0 -x -t 12 -O /mock/home/.ncdu.1234567890 / \
  --exclude System --exclude Volumes --exclude /mock/home/.Trash \
  'expect:90s, actual: 0s')"
[ "$ncdu_output" = "$expected_ncdu_output" ]

codex_main() {
  printf 'codex'
  for argument in "$@"; do printf ' <%s>' "$argument"; done
  printf '\n'
}
[ "$(omcli_main codex)" = "codex" ]
[ "$(omcli_main codex update check)" = "codex <update> <check>" ]

for rejected in 'lockscreen extra' 'ncdu extra'; do
  set -- $rejected
  if omcli_main "$@" >/dev/null 2>&1; then
    echo "accepted unexpected arguments: $rejected" >&2
    exit 1
  fi
done
if omcli_main unknown >/dev/null 2>&1; then
  echo "accepted unknown command" >&2
  exit 1
fi

file bin/omcli-lockscreen | grep -F 'Mach-O' >/dev/null
otool -L bin/omcli-lockscreen | grep -F '/System/Library/PrivateFrameworks/login.framework' >/dev/null

sh tests/codex-state.sh

echo "tests passed"
