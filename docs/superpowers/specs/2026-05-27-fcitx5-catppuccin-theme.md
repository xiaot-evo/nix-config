# Fcitx5 Catppuccin Latte Blue Theme

## Requirement

为 fcitx5 添加 Catppuccin Latte 浅色主题，accent 色为 Blue。

## Design

### Package

利用 nixpkgs 中已有的 `catppuccin-fcitx5` 包，将其添加到 fcitx5 addons 中。

### Theme Config

通过 `xdg.configFile` 设置 `fcitx5/conf/classicui.conf`：

```
Theme=catppuccin-latte-blue
```

### Module

修改 `modules/features/desktop/input-method/fcitx5.nix`：
- `fcitx5.addons` 中添加 `catppuccin-fcitx5`
- 新增 `xdg.configFile."fcitx5/conf/classicui.conf"` 配置

### Impact

- 仅影响启用该 aspect 的 host/user（当前为 acer-swift / xiaot_evo）
- 重新部署后生效，无需额外操作
