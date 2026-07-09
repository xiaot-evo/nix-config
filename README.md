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
├── flake.nix                              # 自动生成，勿手动编辑
├── modules/
│   ├── defaults.nix                        # 全局默认值（stateVersion, strict schema, hm 默认启用）
│   ├── dendritic.nix                       # flake 模块导入声明（flake-file 配置）
│   ├── hosts/
│   │   └── acer-swift/                     # acer-swift 主机配置
│   │       ├── acer-swift.nix              # 主配置（aspect 声明）
│   │       ├── hardware.nix                # 硬件（btrfs 子卷、AMD CPU）
│   │       └── xiaot_evo.nix               # xiaot_evo 用户 aspect
│   └── features/                           # 可复用功能模块，按领域分类
│       ├── apps/                           # 用户应用
│       ├── desktop/                        # 桌面环境
│       ├── dev/                            # 开发环境
│       ├── services/                       # 后台服务
│       ├── system/                         # 系统级配置
│       ├── preference/                     # 偏好设置（cursor-theme、icon-theme）
│       └── security/                       # 安全（gnome-keyring）
├── .github/workflows/test.yml              # CI: nix flake check
├── AGENTS.md                               # AI 助手指令（单一起源参考）
├── AGENTS_PROJECT.md                       # 项目专属信息
├── README.md                               # 本文件
├── docs/
│   ├── den/                                # Den 框架文档
```

## 主机详情

### acer-swift（物理机）

- **硬件**: AMD CPU + NVIDIA GPU（Prime Offload）
- **内核**: Linux ZEN
- **引导**: systemd-boot + Plymouth 静默启动
- **磁盘**: btrfs 子卷（root/home/nix），zstd 压缩
- **网络**: NetworkManager（DHCP 默认）
- **声音**: PipeWire（默认配置）
- **时区/语言**: Asia/Shanghai, zh_CN.UTF-8
- **风扇**: nbfc-linux（Acer Swift SFX14-41G 配置）
- **镜像**: 清华大学 TUNA Nix 镜像 + nix-community/nixos-cuda cache
- **显示管理器**: ly（tty 登录管理器）

## 功能模块

功能模块按领域组织在 `modules/features/` 下，aspect 名 = 文件路径点号分隔。详见 [features/README](modules/features/README.md)。

### 已实现模块

| 领域 | 模块 | 说明 |
|---|---|---|
| apps | `ghostty` | 终端模拟器（默认 fish shell） |
| apps | `zen-browser` | 隐私优先浏览器 |
| apps | `input-method.fcitx5` | 输入法（fcitx5 + rime-ice） |
| apps | `gaming.steam` | Steam 游戏平台 |
| desktop | `wm.niri` | 滚动窗口管理器（niri） |
| desktop | `shell.dms-shell` | DankMaterialShell 桌面 shell |
| desktop | `budgie` | Budgie 桌面环境 |
| dev | `editors.opencode` | OpenCode 编辑器（含 nixos MCP server） |
| dev | `editors.pi-coding-agent` | Pi 编码 agent（13 插件 + 3 扩展 + 20 技能） |
| dev | `editors.zed-editor` | Zed 编辑器（含 keymap/languages/settings） |
| dev | `editors.helix` | Helix 编辑器（含 languages/settings） |
| services | `dae` | 代理（dae + daed 面板） |
| services | `ly` | TTY 显示管理器 |
| services | `greetd` | 备用显示管理器 |
| services | `udiskie` | 自动挂载 |
| services | `printing` | CUPS 打印支持 |
| services | `kdeconnect` | KDE Connect 设备互联 |
| services | `powermanagement` | 电源管理 |
| preference | `cursor-theme` | 光标主题（Catppuccin Mocha）|
| preference | `icon-theme` | 图标主题 |
| security | `gnome-keyring` | GNOME Keyring 密钥管理 |
| system | `boot` | systemd-boot、Plymouth、内核参数（含 zswap） |
| system | `hardware.nvidia` | NVIDIA Prime（Offload 模式） |
| system | `hardware.nbfc-linux` | 笔记本风扇控制 |
| system | `nix` | Nix 设置 |
| system | `sound` | PipeWire 音频 |
| system | `fonts` | 字体 |

### 未实现占位

`desktop/wallpaper/` 有 `.gitkeep` 占位。

## 自定义包

Pi 通过 `llm-agents.nix`（`github:numtide/llm-agents.nix`）提供，其他包通过 Nixpkgs 直接安装。

## CI

`nix flake check` 在 GitHub Actions 上对 ubuntu-latest / macos-latest 执行检查。

CI 会自动创建 `modules/ci-runtime.nix`，可通过 `_module.args.CI` 条件判断。

## 已知待办

- 无 formatter / linter / pre-commit / .envrc 配置
- desktop/wallpaper/ 待实现
- dev/languages/ 和 dev/tools/ 模块待实现（当前无内容）
