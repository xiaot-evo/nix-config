# NixOS Flake — xiaot_evo

基于 [Den](https://den.denful.dev) 框架的 NixOS 配置，采用 **aspects** 模式管理主机与用户。

## 主机

| 主机 | 平台 | 用途 |
|---|---|---|
| `acer-swift` | x86_64-linux (物理机) | Acer Swift SFX14-41G 日常使用 |

## 用户

| 用户 | Shell | 说明 |
|---|---|---|
| `xiaot_evo` | fish | acer-swift 日常用户 |

## 快速开始

```console
# 构建（需要时指定主机）
nix run .#acer-swift

# 重新生成 flake.nix（编辑模块后）
nix run .#write-flake

# 更新 flake 输入
nix flake update den
```

## 项目结构

```
├── flake.nix              # 自动生成，勿手动编辑
├── AGENTS.md              # AI 助手指令（单一起源参考）
├── AGENTS_PROJECT.md      # 项目专属信息
├── README.md              # 本文件
├── ROLLBACK.md            # 部署回滚步骤
├── docs/den/              # Den 框架中文文档
├── .github/workflows/     # CI: nix flake check
└── modules/
    ├── defaults.nix       # 全局默认值（stateVersion, strict schema）
    ├── dendritic.nix      # flake 输入声明 + flake-file 配置
    ├── treefmt.nix        # 多语言格式化（nixfmt + jsonfmt + mdformat + yamlfmt）
    ├── hosts/
    │   └── acer-swift/
    │       ├── acer-swift.nix    # 主机 aspect（includes + nixos 配置）
    │       ├── hardware.nix      # 硬件（btrfs 子卷、AMD CPU、分区）
    │       └── xiaot_evo.nix     # 用户 aspect（includes + home-manager 配置）
    └── features/                  # 可复用 aspect 模块（按领域分目录）
        ├── apps/                  # 用户应用
        │   ├── browsers/          # zen-browser
        │   ├── gaming/            # steam, prismlauncher, gamemode
        │   ├── notes/             # obsidian
        │   └── terminals/         # ghostty, tabby
        ├── desktop/               # 桌面环境
        │   ├── input-method/      # fcitx5
        │   ├── shell/             # dms-shell, noctalia
        │   └── wm/                # niri
        ├── dev/                   # 开发环境
        │   ├── ai/                # ollama, claude-code, pi-coding-agent
        │   ├── editors/           # zed-editor, helix
        │   ├── shell/             # fish, starship
        │   └── tools/             # git, yazi, fastfetch
        ├── preference/            # 偏好设置（theme）
        ├── security/              # 安全（gnome-keyring）
        ├── services/              # 后台服务
        └── system/                # 系统级配置
            └── hardware/          # nvidia, nbfc-linux
```

## 主机详情

### acer-swift（物理机）

- **硬件**: AMD CPU + NVIDIA GPU（Prime Render Offload）
- **内核**: CachyOS BORE x86-64-v3
- **引导**: systemd-boot + Plymouth 静默启动
- **磁盘**: btrfs 子卷（root / nix / home），zstd 压缩，swap 分区
- **网络**: NetworkManager（DHCP 默认）
- **声音**: PipeWire
- **时区/语言**: Asia/Shanghai, zh_CN.UTF-8
- **风扇**: nbfc-linux（Acer Swift SFX14-41G 配置）
- **虚拟化**: KVM（kvm-amd 内核模块）
- **电源管理**: 电源管理服务
- **镜像**: 清华大学 TUNA Nix 镜像 + nix-community/nixos-cuda cache

## 功能模块

功能模块按领域组织在 `modules/features/` 下，aspect 名 = 文件路径点号分隔。

表中 ✅ 表示已引入，❌ 表示已定义但未启用。

### 应用

| Aspect | 说明 | 状态 |
|---|---|---|
| `apps.browsers.zen-browser` | Zen 浏览器（beta） | ✅ |
| `apps.gaming.gamemode` | Feral GameMode 优化 | ❌ |
| `apps.gaming.prismlauncher` | Minecraft 启动器 | ✅ |
| `apps.gaming.steam` | Steam 游戏平台 | ✅ |
| `apps.notes.obsidian` | Obsidian 笔记 | ✅ |
| `apps.terminals.ghostty` | Ghostty 终端模拟器 | ✅ |
| `apps.terminals.tabby` | Tabby 终端（含 hidapi/maple-mono 依赖） | ✅ |

### 桌面

| Aspect | 说明 | 状态 |
|---|---|---|
| `desktop.input-method.fcitx5` | 输入法（fcitx5 + rime-ice） | ✅ |
| `desktop.shell.dms-shell` | DankMaterialShell 桌面 shell | ✅ |
| `desktop.shell.noctalia` | Noctalia 桌面 shell | ❌ |
| `desktop.wm.niri` | niri 滚动窗口管理器（XWayland Satellite） | ✅ |

### 开发

| Aspect | 说明 | 状态 |
|---|---|---|
| `dev.ai.claude-code` | Claude Code CLI（含 MCP 配置） | ✅ |
| `dev.ai.ollama` | Ollama 本地 LLM 服务 | ✅ |
| `dev.ai.pi-coding-agent` | Pi 编码 agent（13 插件 + 3 扩展 + 20 技能） | ✅ |
| `dev.editors.helix` | Helix 编辑器（含 languages/settings） | ✅ |
| `dev.editors.zed-editor` | Zed 编辑器（含 keymap/languages/settings） | ✅ |
| `dev.shell.fish` | Fish shell 配置 | ✅ |
| `dev.shell.starship` | Starship 提示符 | ✅ |
| `dev.tools.fastfetch` | Fastfetch 系统信息 | ❌ |
| `dev.tools.git` | Git 配置 | ✅ |
| `dev.tools.yazi` | Yazi 终端文件管理器 | ✅ |

### 偏好

| Aspect | 说明 | 状态 |
|---|---|---|
| `preference.theme` | Qt/GTK 主题 + 光标 + 图标（Catppuccin Mocha） | ✅ |

### 安全

| Aspect | 说明 | 状态 |
|---|---|---|
| `security.gnome-keyring` | GNOME Keyring 密钥管理 | ✅ |

### 服务

| Aspect | 说明 | 状态 |
|---|---|---|
| `services.dae` | 代理（dae + daed 面板） | ✅ |
| `services.ddns-updater` | 动态 DNS 更新 | ✅ |
| `services.kdeconnect` | KDE Connect 设备互联 | ✅ |
| `services.ly` | TTY 显示管理器 | ✅ |
| `services.powermanagement` | 电源管理 | ✅ |
| `services.printing` | CUPS 打印支持 | ✅ |
| `services.udiskie` | 自动挂载 | ✅ |

### 系统

| Aspect | 说明 | 状态 |
|---|---|---|
| `system.boot` | systemd-boot、Plymouth、内核参数（含 zswap） | ✅ |
| `system.fonts` | 字体（含 Maple Mono NF CN 等） | ✅ |
| `system.hardware.nbfc-linux` | 笔记本风扇控制 | ✅ |
| `system.hardware.nvidia` | NVIDIA Prime（Render Offload 模式） | ✅ |
| `system.network` | NetworkManager | ✅ |
| `system.nh` | nh 工具（NixOS 管理辅助） | ❌ |
| `system.nix` | Nix 设置（experimental-features 等） | ✅ |
| `system.sound` | PipeWire 音频 | ✅ |
| `system.virtualization` | KVM 虚拟化 | ✅ |

## 用户安装包

除 feature modules 外，`xiaot_evo` 用户还通过 `home.packages` 直接安装：

- **命令行**: fastfetch, devenv, android-tools, trash-cli
- **桌面**: warp-terminal, bilibili, resources, marktext, qq, wechat, telegram-desktop, modrinth-app, readest, wpsoffice-cn, obs-studio

## 自定义包

Pi 通过 `llm-agents.nix`（`github:numtide/llm-agents.nix`）提供，其他包通过 Nixpkgs 直接安装。

## CI

`nix flake check` 在 GitHub Actions 上对 ubuntu-latest / macos-latest 执行检查。CI 下 `_module.args.CI = true`。

## 已知待办

- `desktop/shell/noctalia` 已定义但未启用
- `desktop/wallpaper/` 目录为空，待实现
- `dev/tools/fastfetch`、`apps/gaming/gamemode`、`system/nh` 已定义但未引入
