# NixOS Flake — xiaot_evo

基于 [Den](https://den.denful.dev) 框架的 NixOS 配置，采用 **aspects** 模式管理主机与用户。

## 主机

| 主机 | 平台 | 用途 |
|---|---|---|
| `igloo` | x86_64-linux (VM) | 开发测试机 |
| `acer-swift` | x86_64-linux (物理机) | Acer Swift SFX14-41G 日常使用 |

## 用户

| 用户 | Shell | 说明 |
|---|---|---|
| `tux` | fish | igloo 默认用户 |
| `xiaot_evo` | fish | acer-swift 日常用户 |

## 快速开始

```console
# 构建 igloo
nix run .#igloo

# 部署到系统
nix run .#igloo -- switch

# VM 开发（无需重启）
nix run .#vm

# 更新 flake 输入
nix flake update den

# 重新生成 flake.nix（编辑模块后）
nix run .#write-flake
```

## 项目结构

```
├── flake.nix                    # 自动生成，勿手动编辑
├── modules/
│   ├── defaults.nix             # 全局默认值（stateVersion, strict schema）
│   ├── dendritic.nix            # flake 模块导入声明
│   ├── hosts/
│   │   ├── hosts.nix            # 主机/用户/Home 声明入口
│   │   ├── igloo/               # igloo 主机配置
│   │   │   ├── igloo.nix
│   │   │   ├── tux.nix          # tux 用户 aspect
│   │   │   └── vm.nix           # VM 开发配置
│   │   └── acer-swift/          # acer-swift 主机配置
│   │       ├── acer-swift.nix   # 主配置（boot、网络、声音、Nix 设置）
│   │       ├── hardware.nix     # 硬件（btrfs 子卷、AMD CPU）
│   │       ├── nvidia.nix       # NVIDIA Prime 双显卡（Offload 模式）
│   │       ├── nbfc-linux.nix   # 笔记本风扇控制
│   │       └── xiaot_evo.nix    # xiaot_evo 用户 aspect
│   └── features/                # 可复用功能模块
│       ├── nh.nix               # nh 构建支持
│       ├── opencode.nix         # OpenCode 自配置（含 nixos MCP server）
│       ├── niri.nix             # niri 窗口管理器
│       ├── dae.nix              # （存根）
│       ├── ghostty.nix          # （存根）
│       ├── steam.nix            # （存根）
│       └── zed-editor/          # （存根）
├── .github/workflows/test.yml   # CI: nix flake check
├── AGENTS.md                    # AI 助手指令
└── docs/den/                    # Den 框架文档镜像
```

## 主机详情

### acer-swift（物理机）

- **硬件**: AMD CPU + NVIDIA GPU（Prime Offload）
- **内核**: Linux ZEN
- **引导**: systemd-boot + Plymouth 静默启动
- **磁盘**: btrfs 子卷（root/home/nix），zstd 压缩
- **网络**: NetworkManager
- **声音**: PipeWire（ALSA + PulseAudio 兼容）
- **时区/语言**: Asia/Shanghai, zh_CN.UTF-8
- **风扇**: nbfc-linux（Acer Swift SFX14-41G 配置）
- **镜像**: 清华大学 TUNA Nix 镜像 + nix-community/nixos-cuda cache

### igloo（开发 VM）

- 轻量测试环境，用于验证配置后再部署到物理机

## 功能模块

- **nh**: 导出主机/Home app，支持 `nix run .#<host>` 构建和部署
- **opencode**: 封装 OpenCode，集成 nixos MCP server，`nix run .#myopencode`
- **niri**: 基于 niri-nix 的滚动窗口管理器
- 其他模块为存根，等待实现

## CI

`nix flake check` 在 GitHub Actions 上对 ubuntu-latest / macos-latest 执行检查。

CI 会自动创建 `modules/ci-runtime.nix`，可通过 `_module.args.CI` 条件判断。

## 已知待办

- `defaults.nix` 中 tux 的假 grub/filesystem 存根 — 正式部署前移除
- `vm.nix` 的 tty-autologin — 生产环境移除
- dae / ghostty / steam / zed-editor 功能模块待实现
- 无 formatter / linter / pre-commit / .envrc 配置
