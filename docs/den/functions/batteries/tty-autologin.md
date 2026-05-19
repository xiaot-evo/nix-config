# den.batteries.tty-autologin

**源文件**: `modules/aspects/batteries/tty-autologin.nix`

## 用途

物理 TTY 自动登录电池，直接作用于 NixOS 系统配置，实现指定用户的自动登录。

关键行为：
- 签名：`den.batteries.tty-autologin "username"`
- 直接作用在 `nixos` 类上，不经过 `vmVariant`
- 修改 `systemd.services."getty@tty1"` 实现自动登录
- 必须包含在 Host aspect 中

## 使用示例

```nix
den.aspects.my-laptop = {
  includes = [
    (den.batteries.tty-autologin "alice")
  ];
};
```

与 VM 版本的区别：

```nix
# VM 版本：仅 VM 构建生效
(den.batteries.vm-autologin "root")   # → nixos.virtualisation.vmVariant

# 物理机版本：直接生效
(den.batteries.tty-autologin "alice") # → nixos
```

## 实现简析

```
__functor = _self: username: {
  nixos = { pkgs, config, ... }: {
    systemd.services."getty@tty1" = {
      overrideStrategy = "asDropin";
      serviceConfig.ExecStart = [
        ""
        "@${pkgs.util-linux}/sbin/agetty agetty
          --login-program ${config.services.getty.loginProgram}
          --autologin ${username}
          --noclear --keep-baud %I 115200,38400,9600 $TERM"
      ];
    };
  };
};
```

- 与 `den.batteries.vm-autologin` 的 systemd 配置完全相同
- **关键区别**：此版本直接分配到 `nixos` 类，立即生效
  - `vm-autologin` → `nixos.virtualisation.vmVariant`（仅 VM 构建）
  - `tty-autologin` → `nixos`（所有构建）
- 同样使用 `overrideStrategy = "asDropin"` 和 `ExecStart` 重写机制
- 适合开发机、单用户工作站等需要自动登录的场景

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.vm-autologin` | VM 版本，通过 `nixos.virtualisation.vmVariant` 实现，仅影响 VM 构建 |

## 关联文档

- [内置电池](../../../05-内置电池.md) — tty-autologin 电池的快速参考
