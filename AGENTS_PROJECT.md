# AGENTS_PROJECT.md — 项目专属信息

## 可用主机

| 包名 | 主机 | 平台 |
|---|---|---|
| `acer-swift` | acer-swift | `x86_64-linux` |

## 主机：acer-swift

| 属性 | 值 |
|---|---|
| CPU | AMD |
| GPU | NVIDIA + AMD (Prime Render Offload) |
| 引导 | systemd-boot, `/boot/efi` |
| 文件系统 | btrfs |
| 型号 | Acer Swift SFX14-41G |
| 散热 | nbfc-linux |
| 音频 | pipewire |
| 内核 | CachyOS BORE x86-64-v3 |

使用的 aspects：
- `den.batteries.hostname`
- `acer-swift.hardware`
- `system.hardware.nvidia` (nvidiaBusId: PCI:1@0:0:0, amdgpuBusId: PCI:4@0:0:0)
- `system.hardware.nbfc-linux "Acer Swift SFX14-41G"`
- `system.boot`
- `system.nix`
- `system.network` (NetworkManager, 蓝牙, 防火墙)
- `system.sound`
- `services.powermanagement`

NixOS 配置：`pciutils`、时区 `Asia/Shanghai`、语言 `zh_CN.UTF-8`

## 用户：xiaot_evo

| 属性 | 值 |
|---|---|
| Shell | fish |
| 主要用户 | 是 |
| WM | niri (XWayland Satellite) |
| 桌面 Shell | DMS (DankMaterialShell) |
| 显示管理器 | Ly |
| 终端 | ghostty |
| 浏览器 | zen-browser (beta) |
| 输入法 | fcitx5 (RIME, rime-ice) |
| 代理 | daed (dae web dashboard) |
| 编辑器 | zed-editor, helix, opencode |

使用的 aspects（batteries）：
- `define-user`、`primary-user`、`user-shell "fish"`
- `unfree [...]` (warp-terminal, qq, wechat, bilibili, wpsoffice-cn, ventoy, modrinth-app...)
- `insecure [...]` (注释中)

使用的 aspects（features）：
- `security.gnome-keyring`
- `services.dae`、`services.ddns-updater`、`services.ly`、`services.udiskie`、`services.printing`、`services.kdeconnect`
- `system.fonts`
- `desktop.wm.niri`、`desktop.shell.dms-shell`、`desktop.input-method.fcitx5`
- `preference.cursor-theme`、`preference.icon-theme`
- `dev.shell.fish`、`dev.shell.starship`
- `dev.tools.git`、`dev.tools.yazi`
- `dev.editors.opencode`、`dev.editors.zed-editor`、`dev.editors.helix`
- `apps.terminals.ghostty`、`apps.browsers.zen-browser`
- `apps.notes.obsidian`、`apps.gaming.steam`、`apps.gaming.prismlauncher`

provides.to-hosts.nixos：`nix.settings.trusted-users = [ "xiaot_evo" ]`

## 功能模块状态

### 应用
| Aspect | 文件 | 状态 |
|---|---|---|
| `apps.terminals.ghostty` | `apps/terminals/ghostty.nix` | 已实现 |
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

### 开发 / 编辑器
| Aspect | 文件 | 状态 |
|---|---|---|
| `dev.editors.opencode` | `dev/editors/opencode.nix` | 已实现 |
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

## 已知待办事项

- 未配置 formatter、linter、pre-commit hooks 或 .envrc

## 参考

- AGENTS.md — 通用框架参考、构建命令、工作流
- docs/den/ — Den 框架完整文档（中文）
