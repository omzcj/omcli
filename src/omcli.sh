
OMCLI_VERSION="@VERSION@"

omcli_usage() {
  cat <<'EOF'
Usage: omcli <command> [arguments]

Commands:
  lockscreen             Lock the macOS screen immediately
  ncdu                   Scan the startup volume and save an ncdu export
  codex [command]        Manage ChatGPT Desktop reuse of the Codex daemon
  help                   Show this help

Options:
  -h, --help             Show this help
  -v, --version          Show the installed version

Run "omcli codex help" for Codex daemon commands.
EOF
}

omcli_fail() {
  printf 'omcli: %s\n' "$*" >&2
  return 1
}

omcli_resolve_self() {
  omcli_target="$1"
  while [ -L "$omcli_target" ]; do
    omcli_link="$(/usr/bin/readlink "$omcli_target")" || return 1
    case "$omcli_link" in
      /*) omcli_target="$omcli_link" ;;
      *) omcli_target="$(dirname -- "$omcli_target")/$omcli_link" ;;
    esac
  done
  omcli_dir="$(CDPATH='' cd -- "$(dirname -- "$omcli_target")" && pwd)" || return 1
  printf '%s/%s\n' "$omcli_dir" "$(basename -- "$omcli_target")"
}

omcli_external() {
  exec "$@"
}

omcli_run() {
  "$@"
}

omcli_lockscreen_path() {
  omcli_self="$(omcli_resolve_self "$0")" || omcli_fail "cannot resolve executable path" || return
  omcli_bin_dir="$(dirname -- "$omcli_self")"
  printf '%s/../libexec/omcli-lockscreen\n' "$omcli_bin_dir"
}

omcli_helper_is_executable() {
  [ -x "$1" ]
}

omcli_lockscreen() {
  [ "$#" -eq 0 ] || omcli_fail "lockscreen does not accept arguments" || return
  omcli_helper="$(omcli_lockscreen_path)" || return
  omcli_helper_is_executable "$omcli_helper" || omcli_fail "lockscreen helper is not installed" || return
  omcli_external "$omcli_helper"
}

omcli_has_ncdu() {
  command -v ncdu >/dev/null 2>&1
}

omcli_epoch() {
  /bin/date +%s
}

omcli_ncdu() {
  [ "$#" -eq 0 ] || omcli_fail "ncdu does not accept arguments" || return
  omcli_has_ncdu || omcli_fail "ncdu is required" || return
  omcli_started="$(omcli_epoch)"
  omcli_output="$HOME/.ncdu.$omcli_started"
  omcli_run ncdu -0 -x -t 12 -O "$omcli_output" / \
    --exclude System --exclude Volumes --exclude "$HOME/.Trash" || return $?
  omcli_finished="$(omcli_epoch)"
  printf 'expect:90s, actual: %ss\n' "$((omcli_finished - omcli_started))"
}

omcli_main() {
  omcli_command="${1:-help}"
  if [ "$#" -gt 0 ]; then shift; fi
  case "$omcli_command" in
    help|-h|--help)
      [ "$#" -eq 0 ] || omcli_fail "help does not accept arguments" || return
      omcli_usage
      ;;
    version|-v|--version)
      [ "$#" -eq 0 ] || omcli_fail "version does not accept arguments" || return
      printf 'omcli %s\n' "$OMCLI_VERSION"
      ;;
    lockscreen) omcli_lockscreen "$@" ;;
    ncdu) omcli_ncdu "$@" ;;
    codex) codex_main "$@" ;;
    *) omcli_usage >&2; omcli_fail "unknown command: $omcli_command" ;;
  esac
}

if [ "${OMCLI_SOURCE_ONLY:-0}" != "1" ]; then
  omcli_main "$@"
fi
