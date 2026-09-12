# omcli

`omcli` 将多个 macOS 小工具合并到一个命令中：

```sh
omcli lockscreen
omcli ncdu
omcli ncdu dump
omcli ncdu read
omcli codex status
omcli xcodex
```

不带参数运行 `omcli` 只显示帮助，不会修改系统。项目仅支持运行 macOS
的 Apple Silicon（`arm64`）设备。

## 安装

```sh
brew install oh-my-brew/tap/omcli
```

## 命令

### 锁屏

`omcli lockscreen` 立即锁定 macOS 屏幕。

### ncdu 快照

- `omcli ncdu` 和 `omcli ncdu help` 只显示帮助，不扫描磁盘。
- `omcli ncdu dump` 扫描启动卷并生成 `~/.ncdu.<时间戳>`。扫描排除
  `System`、`Volumes` 和 `~/.Trash`，线程数取自当前设备的
  `sysctl hw.logicalcpu`。
- `omcli ncdu read [FILE]` 显示指定快照的项目数和占比。省略 `FILE` 时，
  自动选择数字时间戳最大的 `~/.ncdu.<时间戳>` 文件。

示例：

```sh
omcli ncdu dump
omcli ncdu read
omcli ncdu read ~/.ncdu.1788940800
```

`dump` 会输出快照路径和耗时，不覆盖已有快照。自动选择快照时只接受文件名
为 `.ncdu.` 加纯数字时间戳的普通文件。

### Codex daemon 管理

- `omcli codex` 是只读命令，等价于 `omcli codex status`。
- `omcli codex start|stop|restart` 管理 ChatGPT Desktop 对 Codex managed
  app-server daemon 的复用。
- `omcli codex update check|latest|VERSION` 检查、升级或回退 standalone
  Codex。

这组命令保留既有 `CODEX_REMOTE_*` 环境变量覆盖和 `~/.codex` 运行目录。
它是此前解决多客户端 writer 冲突的兼容方案，现已不再作为日常入口，相关
ChatGPT Cask 也不再维护。代码仅保留并随仓库迁移更新地址；不要继续依赖它
固定或降级 ChatGPT Desktop。

### active writer 应急恢复

```sh
omcli xcodex
```

该命令查找所有正在持有 `~/.codex/thread-writer-locks` 中文件的进程，去重后
向它们发送 `SIGTERM`。没有持有进程时直接成功退出，不发送信号。

这是明确出现 `active writer` 或会话占用时的人工应急命令，可能终止 ChatGPT
Desktop、Codex 或正在生成的响应，不应自动执行，也不能代替正确的多设备连接
方式。

## 多设备使用结论

### M5、iPhone 连接 M1/M2

当前日常入口是 M5 ChatGPT Desktop 和 iPhone，通过 SSH 使用 M1、M2；不再
直接操作 M1、M2 上的 ChatGPT Desktop 会话。M5 和 iPhone 同时连接 M1、M2
已经实机验证，没有重现此前的 `active writer` 问题。

因此 M1、M2 已改用官方 Homebrew ChatGPT，不再固定 Desktop
`26.818.61809`。关闭远端 ChatGPT.app 不会中断已有 SSH 会话和 managed
daemon，但 Computer Use 仍依赖 ChatGPT.app 包内资源，所以应用仍需安装，
只是不必常驻打开。

### iPhone 连接 M5

iPhone 和 M5 ChatGPT Desktop 按不同顺序打开 M5 上的同一会话时，仍可能发生
writer 占用。当前候选方案是让 M5 Desktop 通过指向 M5 自身的 SSH alias 工作，
并在 M5 的远端 login shell 设置：

```sh
export CODEX_SSH_SKIP_APP_SERVER_BOOT=true
```

当前 Desktop 的 SSH 路径会据此跳过独立的
`codex app-server --listen unix://`，再通过 `codex app-server proxy` 连接已经
运行的 managed daemon 控制 socket：

```text
M5 ChatGPT → SSH 127.0.0.1 → app-server proxy
                                      ↓
M5 managed daemon control socket ← iPhone
```

`CODEX_SSH_SKIP_APP_SERVER_BOOT` 是内部且随版本变化的开关，不由 `omcli`
自动设置。它必须配合预先启动、已启用 remote control 的 managed daemon；
单独设置变量不会启动服务。正式启用前仍需验证 M5 回环 SSH、共享 daemon 和
失败回退流程。

## 开发

```sh
make build
sh tests/test.sh
```

测试不会真实锁屏、扫描磁盘、打开 ncdu 界面、终止 writer 进程或执行 Codex
生命周期命令。路由测试会替换外部执行边界，并默认阻止会影响系统的 Codex
操作。锁屏辅助程序只会被编译并检查是否为 Mach-O，不会运行。

## 发布

修改 `VERSION` 后推送到 `main`。Release workflow 会执行隔离测试，并将
`omcli-VERSION.tar.gz` 发布到名为 `vVERSION` 的 GitHub Release。发布自动化
使用 `oh-my-infra/brew-ci`，发布结果位于 `oh-my-brew/omcli`。

手动运行 Release workflow 默认只验证和打包，不发布：`publish=false` 使用
现有版本运行验证并检查两次打包结果一致，不修改 `VERSION` 或创建 tag/release。
显式选择 `publish=true` 才会发布；现有 main 源码 push 仍按原规则自动发布。

## 许可证

Codex 管理和 omcli 集成代码使用 [MIT License](LICENSE)。从
`omzcj/dotfiles` 迁移的 ncdu 封装，以及从 `omzcj/lockscreen` 迁移的锁屏
辅助程序，继续使用 [Apache License 2.0](LICENSE-APACHE)；组件说明见
[NOTICE](NOTICE)。
