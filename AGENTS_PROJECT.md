# AGENTS_PROJECT.md — 项目专属信息

## 可用主机

| 包名 | 主机 | 平台 |
|---|---|---|
| `acer-swift` | acer-swift | `x86_64-linux` |

## 主机：acer-swift

| 属性 | 值 |
|---|---|
| CPU | AMD |
| GPU | NVIDIA + AMD |
| 引导 | systemd-boot, `/boot/efi` |
| 文件系统 | btrfs |
| 型号 | Acer Swift SFX14-41G |
| 散热 | nbfc-linux |
| 音频 | pipewire |

使用的 aspects：
- `den.batteries.hostname`
- `acer-swift.hardware`
- `system.hardware.nvidia`
- `system.hardware.nbfc-linux`
- `system.boot "/boot/efi"`
- `system.nix`
- `system.sound`

## 用户：xiaot_evo

| 属性 | 值 |
|---|---|
| Shell | bash |
| 主要用户 | 是 |
| 非自由软件 | qq, wechat, bilibili, wpsoffice-cn |
| WM | niri |
| 终端 | ghostty（shell: fish） |

使用的 aspects：
- `den.batteries.define-user`
- `den.batteries.primary-user`
- `den.batteries.user-shell "bash"`
- `den.batteries.unfree [...]`
- `den.batteries.self'`
- `services.dae`
- `services.ly`
- `services.udiskie`
- `services.printing`
- `services.kdeconnect`
- `system.fonts`
- `desktop.wm.niri`
- `desktop.shell.dms-shell`
- `dev.editors.zed-editor`
- `dev.editors.helix`
- `desktop.input-method.fcitx5`
- `apps.terminals.ghostty`
- `apps.browsers.zen-browser`

`self'.packages`：opencode, fish, starship, git

## 功能模块状态

### 应用
| Aspect | 文件 | 状态 |
|---|---|---|
| `apps.terminals.ghostty` | `apps/terminals/ghostty.nix` | 已实现 |
| `apps.browsers.zen-browser` | `apps/browsers/zen-browser.nix` | 已实现 |
| `apps.gaming.steam` | `apps/gaming/steam.nix` | 已实现 |

### 桌面
| Aspect | 文件 | 状态 |
|---|---|---|
| `desktop.wm.niri` | `desktop/wm/niri.nix` | 已实现 |
| `desktop.shell.dms-shell` | `desktop/shell/dms-shell.nix` | 已实现 |
| `desktop.input-method.fcitx5` | `desktop/input-method/fcitx5.nix` | 已实现 |
| `desktop.budgie` | `desktop/budgie.nix` | 已禁用 |
| `desktop.wallpaper` | `desktop/wallpaper/` | 空目录 |

### 开发 / 编辑器
| Aspect | 文件 | 状态 |
|---|---|---|
| `dev.editors.zed-editor` | `dev/editors/zed-editor/` | 已实现 |
| `dev.editors.helix` | `dev/editors/helix/` | 已实现 |

### 服务
| Aspect | 文件 | 状态 |
|---|---|---|
| `services.dae` | `services/dae.nix` | 已实现 |
| `services.ly` | `services/ly.nix` | 已实现 |
| `services.greetd` | `services/greetd.nix` | 已禁用 |
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
| `system.network` | `system/network.nix` | 空桩 |
| `system.nh` | `system/nh.nix` | 已实现 |
| `system.hardware.nvidia` | `system/hardware/nvidia.nix` | 已实现 |
| `system.hardware.nbfc-linux` | `system/hardware/nbfc-linux.nix` | 已实现 |

### 安全
| Aspect | 文件 | 状态 |
|---|---|---|
| `security.gnome-keyring` | `security/gnome-keyring.nix` | 已实现 |

## 已知待办事项

- `defaults.nix` 中有假的 grub/filesystem 桩代码 — 实际部署前删除
- `features/desktop/wallpaper/` 是空目录 — 需要实现
- 未配置 formatter、linter、pre-commit hooks 或 .envrc

## 参考

- AGENTS.md — 通用框架参考、构建命令、工作流
- docs/den/ — Den 框架完整文档（中文）
