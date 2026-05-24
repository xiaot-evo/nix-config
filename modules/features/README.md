# Features

Feature modules organized by domain. Each `.nix` file defines a `den.aspects.*`
aspect that can be conditionally included by hosts and users.

## Structure

```
apps/                   用户应用（GUI / 面向用户）
├── gaming/             steam
├── input-method/       fcitx5
└── terminals/          ghostty, kitty, alacritty

desktop/                桌面环境组件
├── wm/                 niri, hyprland
├── shell/              dms-shell, waybar, rofi, mako
├── lockscreen/         swaylock
├── wallpaper/
└── polkit/

dev/                    开发环境
├── editors/            neovim, opencode, zed, vscode
├── languages/          rust, go, node, python
├── tools/              git, docker, nh, lazygit

services/               后台服务 / 守护进程
├── dae, syncthing, nbfc-linux

shell/                  交互式 Shell 环境
├── fish, starship, bash, zsh, aliases

system/                 系统级配置
├── hardware/           GPU, 蓝牙, CPU, nbfc-linux
├── boot.nix            引导
├── network.nix         网络
├── locale.nix          本地化
├── sound.nix           音频
└── nix.nix             Nix 设置

themes/                 主题外观（未来）
├── fonts, gtk, cursors

security/               安全（未来）
├── gnupg, ssh, sops
```

## Aspect Naming

Aspect 名 = 文件路径，点号分隔：

| 路径                                  | Aspect                                     |
| ------------------------------------- | ------------------------------------------ |
| `dev/editors/neovim.nix`              | `den.aspects.dev.editors.neovim`           |
| `desktop/wm/niri.nix`                 | `den.aspects.desktop.wm.niri`              |
| `system/hardware/nvidia.nix`          | `den.aspects.system.hardware.nvidia`       |
| `apps/terminals/ghostty.nix`          | `den.aspects.apps.terminals.ghostty`       |
| `shell/fish.nix`                      | `den.aspects.shell.fish`                   |

## Usage

```nix
den.aspects.myhost = {
  includes = [
    den.aspects.dev.editors.neovim
    den.aspects.desktop.wm.niri
    den.aspects.system.boot
  ];
};
```
