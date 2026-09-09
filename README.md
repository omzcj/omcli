# omcli

`omcli` consolidates small macOS utilities behind one command:

```sh
omcli lockscreen
omcli ncdu
omcli codex status
```

Running `omcli` without arguments displays help and does not change the system.
Only Apple Silicon Macs (`arm64`) running macOS are supported.

## Installation

```sh
brew install omzcj/omzcj/omcli
```

## Commands

- `omcli lockscreen` immediately locks the macOS screen.
- `omcli ncdu` scans the startup volume with `ncdu` and writes an export named
  `~/.ncdu.<timestamp>`, excluding `System`, `Volumes`, and `~/.Trash`.
- `omcli codex` is read-only and equivalent to `omcli codex status`.
- `omcli codex start|stop|restart` manages ChatGPT Desktop reuse of the Codex
  managed app-server daemon.
- `omcli codex update check|latest|VERSION` checks, updates, or rolls back the
  standalone Codex installation.

The Codex integration preserves the existing `CODEX_REMOTE_*` environment
overrides and the existing `~/.codex` runtime layout.

## License

The Codex management and omcli integration code use the MIT License in
`LICENSE`. The `ncdu` wrapper migrated from `omzcj/dotfiles` and the lockscreen
helper migrated from `omzcj/lockscreen` retain the Apache License 2.0 in
`LICENSE-APACHE`; see `NOTICE` for the component summary.

## Development

```sh
make build
sh tests/test.sh
```

The test suite never invokes screen locking, disk scanning, or a real Codex
lifecycle command. It uses source-only router tests with the external execution
boundary replaced by mocks and default-deny guards around Codex system effects.
The lockscreen helper is compiled and inspected as a Mach-O binary but is never
run.

## Release

Update `VERSION` and push the change to `main`. The release workflow validates
the isolated tests and publishes `omcli-VERSION.tar.gz` to a GitHub Release
tagged `vVERSION`.
