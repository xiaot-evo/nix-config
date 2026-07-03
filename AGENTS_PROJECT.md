# AGENTS_PROJECT.md — 项目专属信息

> AGENTS.md 的补充，包含本项目所有主机、用户及功能模块的具体信息。

---

## 可用主机

| 包名 | 主机名 | 平台 | 备注 |
|---|---|---|---|
| `acer-swift` | acer-swift | `x86_64-linux` | 主力笔记本 |

---

## 主机：acer-swift

| 属性 | 值 |
|---|---|
| CPU | AMD |
| GPU | NVIDIA + AMD (Prime Render Offload) |
| 引导 | systemd-boot，`/boot/efi` |
| 文件系统 | btrfs |
| 型号 | Acer Swift SFX14-41G |
| 散热 | nbfc-linux（`"Acer Swift SFX14-41G"`） |
| 音频 | pipewire |
| 内核 | CachyOS BORE x86-64-v3 |
| 时区 | `Asia/Shanghai` |
| 语言 | `zh_CN.UTF-8` |

### 使用的 aspects

- `den.batteries.hostname`
- `acer-swift.hardware`
- `system.hardware.nvidia`（nvidiaBusId: `PCI:1@0:0:0`，amdgpuBusId: `PCI:4@0:0:0`）
- `system.hardware.nbfc-linux`（型号 `"Acer Swift SFX14-41G"`）
- `system.boot`、`system.nix`、`system.network`（NetworkManager + 蓝牙 + 防火墙）
- `system.sound`、`services.powermanagement`

---

## 用户：xiaot_evo

| 属性 | 值 |
|---|---|
| Shell | fish |
| 主要用户 | 是 |
| WM | niri（XWayland Satellite） |
| 桌面 Shell | DMS（DankMaterialShell） |
| 显示管理器 | Ly |
| 终端 | ghostty |
| 浏览器 | zen-browser（beta） |
| 输入法 | fcitx5（RIME + rime-ice） |
| 代理 | daed（dae web dashboard） |
| 编辑器 | zed-editor、helix、pi-coding-agent |

### Batteries aspects

- `define-user`、`primary-user`、`user-shell "fish"`
- `unfree [...]` — warp-terminal, qq, wechat, bilibili, wpsoffice-cn, ventoy, modrinth-app...
- `insecure [...]` — 当前全部注释中

### Feature aspects

| 分类 | aspects |
|---|---|
| 安全 | `security.gnome-keyring` |
| 服务 | `services.dae`、`services.ddns-updater`、`services.ly`、`services.udiskie`、`services.printing`、`services.kdeconnect` |
| 系统 | `system.fonts` |
| 桌面 | `desktop.wm.niri`、`desktop.shell.dms-shell`、`desktop.input-method.fcitx5` |
| 偏好 | `preference.cursor-theme`、`preference.icon-theme` |
| 开发 | `dev.shell.fish`、`dev.shell.starship`、`dev.tools.git`、`dev.tools.yazi` |
| 编辑器 | `dev.editors.opencode`、`dev.editors.pi-coding-agent`（含 13 个 npm 插件 + 3 个 TS 扩展）、`dev.editors.zed-editor`、`dev.editors.helix` |
| 应用 | `apps.terminals.ghostty`、`apps.terminals.tabby`、`apps.browsers.zen-browser`、`apps.notes.obsidian`、`apps.gaming.steam`、`apps.gaming.prismlauncher` |

### provides.to-hosts.nixos

```nix
home-manager.backupFileExtension = "bak";
nix.settings.trusted-users = [ "xiaot_evo" ];
```

---

## 功能模块清单

### 应用

| Aspect | 文件 | 状态 |
|---|---|---|
| `apps.terminals.ghostty` | `apps/terminals/ghostty.nix` | 已实现 |
| `apps.terminals.tabby` | `apps/terminals/tabby.nix` | 已实现 |
| `apps.browsers.zen-browser` | `apps/browsers/zen-browser.nix` | 已实现 |
| `apps.notes.obsidian` | `apps/notes/obsidian.nix` | 已实现 |
| `apps.gaming.steam` | `apps/gaming/steam.nix` | 已实现 |
| `apps.gaming.prismlauncher` | `apps/gaming/prismlauncher.nix` | 已实现 |
| `apps.gaming.gamemode` | `apps/gaming/gamemode.nix` | 已实现 |

### 桌面

| Aspect | 文件 | 状态 |
|---|---|---|
| `desktop.wm.niri` | `desktop/wm/niri.nix` | 已实现 |
| `desktop.shell.dms-shell` | `desktop/shell/dms-shell.nix` | 已实现 |
| `desktop.input-method.fcitx5` | `desktop/input-method/fcitx5.nix` | 已实现 |

### 开发

| Aspect | 文件 | 状态 |
|---|---|---|
| `dev.editors.opencode` | `dev/editors/opencode.nix` | 已实现 |
| `dev.editors.pi-coding-agent` | `dev/editors/pi-coding-agent.nix` | 已实现 |
| `dev.editors.zed-editor` | `dev/editors/zed-editor/` | 已实现 |
| `dev.editors.helix` | `dev/editors/helix/` | 已实现 |
| `dev.shell.fish` | `dev/shell/fish.nix` | 已实现 |
| `dev.shell.starship` | `dev/shell/starship.nix` | 已实现 |
| `dev.tools.git` | `dev/tools/git.nix` | 已实现 |
| `dev.tools.yazi` | `dev/tools/yazi.nix` | 已实现 |
| `dev.tools.fastfetch` | `dev/tools/fastfetch.nix` | 已实现 |

### 偏好

| Aspect | 文件 | 状态 |
|---|---|---|
| `preference.cursor-theme` | `preference/cursor-theme.nix` | 已实现 |
| `preference.icon-theme` | `preference/icon-theme.nix` | 已实现 |

### 安全

| Aspect | 文件 | 状态 |
|---|---|---|
| `security.gnome-keyring` | `security/gnome-keyring.nix` | 已实现 |

### 服务

| Aspect | 文件 | 状态 |
|---|---|---|
| `services.dae` | `services/dae.nix` | 已实现 |
| `services.ddns-updater` | `services/ddns-updater.nix` | 已实现 |
| `services.ly` | `services/ly.nix` | 已实现 |
| `services.udiskie` | `services/udiskie.nix` | 已实现 |
| `services.printing` | `services/printing.nix` | 已实现 |
| `services.kdeconnect` | `services/kdeconnect.nix` | 已实现 |
| `services.powermanagement` | `services/powermanagement.nix` | 已实现 |

### 系统

| Aspect | 文件 | 状态 |
|---|---|---|
| `system.boot` | `system/boot.nix` | 已实现 |
| `system.nix` | `system/nix.nix` | 已实现 |
| `system.sound` | `system/sound.nix` | 已实现 |
| `system.fonts` | `system/fonts.nix` | 已实现 |
| `system.network` | `system/network.nix` | 已实现 |
| `system.nh` | `system/nh.nix` | 已实现 |
| `system.hardware.nvidia` | `system/hardware/nvidia.nix` | 已实现 |
| `system.hardware.nbfc-linux` | `system/hardware/nbfc-linux.nix` | 已实现 |

### Pi Coding Agent 配置详情

| 配置项 | 说明 |
|---|---|
| 提供商 | opencode (DeepSeek) |
| 模型 | deepseek-v4-flash-free |
| npm 插件 | 13 个（见 [plugins-overview](modules/features/dev/editors/pi-coding-agent/docs/plugins-overview.md)）|
| TS 扩展 | notify.ts, plan-mode（通知 + 计划模式）|
| MCP 服务器 | nixos (mcp-nixos) |
| 权限系统 | @gotgenes/pi-permission-system (allow/ask/deny) |
| 检查点 | @ayulab/pi-rewind (/rewind 交互式导航) |
| 技能系统 | superpowers-zh (20 个技能) |
| 使用教程 | [usage-guide.md](modules/features/dev/editors/pi-coding-agent/docs/usage-guide.md) |

---

## 已知待办

- 未配置 formatter / linter / pre-commit hooks / .envrc
- @plannotator/pi-extension 已从配置移除（如需手动卸载：`pi uninstall @plannotator/pi-extension`）

---

## 参考

- `AGENTS.md` — 通用参考、构建命令、Den 框架、工作流
- `docs/den/` — Den 框架完整中文文档
- `docs/superpowers/` — superpowers 技能文档（已归档）
