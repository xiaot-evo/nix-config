# 回滚计划

## 触发条件

若部署后出现以下情况之一，立即回滚：

- `nixos-rebuild switch` 失败
- 系统无法启动
- 关键功能（网络、桌面、输入法）异常
- 性能严重退化

## 回滚步骤

### 方式一：切换到上一个 Generation（推荐）

```console
# 列出可用的 generations
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# 切换到上一个成功 generation（例如 123）
sudo nix-env --switch-generation 123 -p /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

### 方式二：使用 Git 恢复

```console
# 查看最近的变更
git log --oneline -10

# 回滚到上一个提交
git revert HEAD --no-edit

# 或者硬回滚到指定提交
git reset --hard <commit-hash>

# 部署回滚后的配置
sudo nixos-rebuild switch --flake .#acer-swift
```

### 方式三：使用 NixOS 引导菜单

1. 重启系统
1. 在 systemd-boot 菜单中选择上一个 NixOS generation
1. 系统将加载部署前的配置

## 数据库注意事项

本项目为 NixOS 配置项目，无数据库迁移需求。

## 回滚时间

| 方式 | 预计时间 |
|------|---------|
| 切换 Generation | < 1 分钟 |
| Git revert + 重建 | < 5 分钟 |
| 引导菜单回滚 | < 1 分钟（需重启） |
