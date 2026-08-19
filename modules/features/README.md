# Features

Feature modules organized by domain. Each `.nix` file defines a `den.aspects.*`
aspect that can be conditionally included by hosts and users.

## Structure

```
apps/                   用户应用（GUI / 面向用户）
├── terminals/          ghostty
└── gaming/             steam

desktop/                桌面环境组件
├── wm/                 niri
├── shell/              dms-shell
├── input-method/       fcitx5
├── wallpaper/          （空目录）
└── budgie.nix          已禁用

dev/                    开发环境
└── editors/            zed-editor, helix

services/               后台服务 / 守护进程
├── dae, ly, greetd(disabled), udiskie, printing, kdeconnect, powermanagement

system/                 系统级配置
├── hardware/           nvidia, nbfc-linux
├── boot.nix            引导
├── network.nix         网络（空桩）
├── nh.nix              nh 工具
├── fonts.nix           字体
├── sound.nix           音频
└── nix.nix             Nix 设置

security/               安全
└── gnome-keyring.nix   GNOME Keyring
```

## Aspect Naming

Aspect 名 = 文件路径，点号分隔：

| 路径 | Aspect |
| ------------------------------------- | ------------------------------------------ |
| `dev/editors/zed-editor.nix` | `den.aspects.dev.editors.zed-editor` |
| `desktop/wm/niri.nix` | `den.aspects.desktop.wm.niri` |
| `system/hardware/nvidia.nix` | `den.aspects.system.hardware.nvidia` |
| `apps/terminals/ghostty.nix` | `den.aspects.apps.terminals.ghostty` |

## Usage

```nix
den.aspects.myhost = {
  includes = [
    den.aspects.dev.editors.helix
    den.aspects.desktop.wm.niri
    den.aspects.system.boot
  ];
};
```
