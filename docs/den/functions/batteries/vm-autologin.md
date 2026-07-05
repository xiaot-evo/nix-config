# den.batteries.vm-autologin

**源文件**: `modules/aspects/batteries/vm-autologin.nix`

## 用途

VM 自动 TTY 登录电池，用于 `nixos-rebuild build-vm` 构建的虚拟机场景。仅在 VM variant 构建中生效，不影响物理机行为。

关键行为：

- 签名：`den.batteries.vm-autologin "username"`
- 使用 `nixos.virtualisation.vmVariant` 包装模块，只影响 VM 构建
- 修改 `systemd.services."getty@tty1"` 实现自动登录
- 必须包含在 Host aspect 中

## 使用示例

```nix
den.aspects.my-laptop = {
  includes = [
    (den.batteries.vm-autologin "root")
  ];
};
```

## 实现简析

```
__functor = _self: username: {
  nixos.virtualisation.vmVariant = { pkgs, config, ... }: {
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

- `nixos.virtualisation.vmVariant` 是 NixOS 提供的选项，用于定义仅在 `build-vm` 时生效的配置变更
- `overrideStrategy = "asDropin"` 以 drop-in 方式覆盖 systemd 服务配置而非整体替换
- `ExecStart` 先清空（`""`）再设置新的启动命令，确保自动登录参数生效
- `--autologin ${username}` 使指定用户自动登录 tty1
- 与 `den.batteries.tty-autologin` 的关键区别：此版本使用 `vmVariant` 包裹，仅影响 VM 构建

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.tty-autologin` | 物理 TTY 版本，实现结构相同但直接作用在 nixos 类上 |

## 关联文档

- [内置电池](../../../05-%E5%86%85%E7%BD%AE%E7%94%B5%E6%B1%A0.md) — vm-autologin 电池的快速参考
