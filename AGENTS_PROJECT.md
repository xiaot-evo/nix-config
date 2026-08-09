# AGENTS_PROJECT.md — 项目信息

> AGENTS.md 的补充，包含本项目所有主机、用户及功能模块的具体信息。

______________________________________________________________________

## 主机

| 主机名 | 平台 | 备注 |
|---|---|---|
| `acer-swift` | `x86_64-linux` | 主力笔记本 |

______________________________________________________________________

## 主机：acer-swift

| 属性 | 值 |
|---|---|
| CPU | AMD |
| GPU | NVIDIA + AMD（Prime Render Offload） |
| 引导 | systemd-boot，`/boot/efi` |
| 文件系统 | btrfs（子卷: root, nix, home） |
| 型号 | Acer Swift SFX14-41G |
| 散热 | nbfc-linux |
| 音频 | PipeWire |
| 内核 | CachyOS BORE x86-64-v3 |
| 时区 | `Asia/Shanghai` |
| 语言 | `zh_CN.UTF-8` |

### 使用的 aspects

```text
den.batteries.hostname
acer-swift.hardware
system.hardware.nvidia         (nvidiaBusId: PCI:1@0:0:0, amdgpuBusId: PCI:4@0:0:0)
system.hardware.nbfc-linux     (Acer Swift SFX14-41G)
system.boot
system.nix
system.network
system.sound
system.virtualization
services.powermanagement
services.atftpd
```

______________________________________________________________________

## 用户：xiaot_evo

| 属性 | 值 |
|---|---|
| Shell | fish |
| 主要用户 | 是 |
| WM | niri（XWayland Satellite） |
| 桌面 Shell | DMS（DankMaterialShell） |
| 显示管理器 | Ly |
| 终端 | ghostty |
| 浏览器 | Zen Browser（Flatpak） |
| 输入法 | fcitx5（RIME + rime-ice） |
| 代理 | dae / daed |
| 编辑器 | Claude Code、Pi、Zed、Helix |

### Batteries

```text
define-user
primary-user
user-shell "fish"
unfree [...]       (bilibili, warp-terminal, ventoy, modrinth-app, modrinth-app-unwrapped)
insecure [...]     (ventoy-1.1.12)
```

### Feature aspects

```text
# 服务
services.dae
services.ddns-updater
services.ly
services.udiskie
services.printing
services.kdeconnect
services.flathub      (parametric — 含 QQ、WeChat、DingTalk、WPS Flatpak)

# 系统
system.fonts

# 桌面
desktop.wm.niri
desktop.shell.dms-shell
desktop.input-method.fcitx5

# 偏好
preference.theme      (含 iconTheme / cursorTheme / fontFamily)

# 开发
dev.shell.fish
dev.shell.starship
dev.tools.git
dev.tools.yazi
dev.tools.distrobox
dev.ai.claude-code
dev.ai.pi-coding-agent
dev.editors.zed-editor
dev.editors.helix

# 应用
apps.terminals.ghostty
apps.notes.obsidian
apps.gaming.steam
apps.gaming.prismlauncher
```

### 已注释（保留备用）

```text
# 本地 AI 推理，当前未启用
# dev.ai.ollama

# 游戏控制器相关，当前未启用
# apps.gaming.opengamepadui
# apps.gaming.lutris

# AI 编码辅助工具，当前未启用
# dev.ai.antigravity-cli

# 终端信息展示，当前未启用
# dev.tools.fastfetch
```

______________________________________________________________________

## 功能模块清单

### 应用

| Aspect | 文件 | 已引入 |
|---|---|---|
| `apps.gaming.gamemode` | `apps/gaming/gamemode.nix` | ❌ |
| `apps.gaming.lutris` | `apps/gaming/lutris.nix` | ❌（已注释） |
| `apps.gaming.opengamepadui` | `apps/gaming/opengamepadui.nix` | ❌（已注释） |
| `apps.gaming.prismlauncher` | `apps/gaming/prismlauncher.nix` | ✅ |
| `apps.gaming.steam` | `apps/gaming/steam.nix` | ✅ |
| `apps.notes.obsidian` | `apps/notes/obsidian.nix` | ✅ |
| `apps.terminals.ghostty` | `apps/terminals/ghostty.nix` | ✅ |

### 桌面

| Aspect | 文件 | 已引入 |
|---|---|---|
| `desktop.input-method.fcitx5` | `desktop/input-method/fcitx5.nix` | ✅ |
| `desktop.shell.dms-shell` | `desktop/shell/dms-shell/dms-shell.nix` | ✅ |
| `desktop.wm.niri` | `desktop/wm/niri.nix` | ✅ |

### 开发

| Aspect | 文件 | 已引入 |
|---|---|---|
| `dev.ai.claude-code` | `dev/ai/claude-code.nix` | ✅ |
| `dev.ai.ollama` | `dev/ai/ollama.nix` | ❌（已注释） |
| `dev.ai.pi-coding-agent` | `dev/ai/pi-coding-agent/pi-coding-agent.nix` | ✅ |
| `dev.editors.helix` | `dev/editors/helix/helix.nix` | ✅ |
| `dev.editors.zed-editor` | `dev/editors/zed-editor/zed-editor.nix` | ✅ |
| `dev.shell.fish` | `dev/shell/fish.nix` | ✅ |
| `dev.shell.starship` | `dev/shell/starship.nix` | ✅ |
| `dev.tools.distrobox` | `dev/tools/distrobox.nix` | ✅ |
| `dev.tools.fastfetch` | `dev/tools/fastfetch.nix` | ❌ |
| `dev.tools.git` | `dev/tools/git.nix` | ✅ |
| `dev.tools.yazi` | `dev/tools/yazi.nix` | ✅ |

### 偏好

| Aspect | 文件 | 已引入 |
|---|---|---|
| `preference.theme` | `preference/theme.nix` | ✅ |

> `preference.theme` 统一配置 iconTheme、cursorTheme、fontFamily 并通过 quirk 共享给 dms-shell 和 flathub 等消费者。

### 服务

| Aspect | 文件 | 已引入 |
|---|---|---|
| `services.atftpd` | `services/atftpd.nix` | ✅ |
| `services.dae` | `services/dae.nix` | ✅ |
| `services.ddns-updater` | `services/ddns-updater.nix` | ✅ |
| `services.flathub` | `services/flathub.nix` | ✅ |
| `services.kdeconnect` | `services/kdeconnect.nix` | ✅ |
| `services.ly` | `services/ly.nix` | ✅ |
| `services.powermanagement` | `services/powermanagement.nix` | ✅ |
| `services.printing` | `services/printing.nix` | ✅ |
| `services.udiskie` | `services/udiskie.nix` | ✅ |

### 系统

| Aspect | 文件 | 已引入 |
|---|---|---|
| `system.boot` | `system/boot.nix` | ✅ |
| `system.fonts` | `system/fonts.nix` | ✅ |
| `system.hardware.nbfc-linux` | `system/hardware/nbfc-linux.nix` | ✅ |
| `system.hardware.nvidia` | `system/hardware/nvidia.nix` | ✅ |
| `system.network` | `system/network.nix` | ✅ |
| `system.nix` | `system/nix.nix` | ✅ |
| `system.sound` | `system/sound.nix` | ✅ |
| `system.virtualization` | `system/virtualization.nix` | ✅ |

> `system.nh` 已移至 `modules/flake/nh.nix`，属于 flake 级输出，不在 features 目录中。
