# den.batteries.maid

**源文件**: `modules/aspects/batteries/maid.nix`

## 用途

[nix-maid](https://github.com/nix-community/nix-maid) 声明式家政服务集成电池。nix-maid 是一个用于管理 systemd timer 定时任务的家政服务工具。

关键行为：
- 注册 `maid` 类，描述为 "nix-maid user environment"
- 通过 `den.lib.home-env.makeHomeEnv` 构建
- `className = "maid"`，`optionPath = "nix-maid"`
- **仅支持 NixOS**（`supportedOses = [ "nixos" ]`）
- 转发到 `users.users.<userName>.maid`
- 需要 `inputs.nix-maid` flake 输入

## 使用示例

```nix
{
  inputs = {
    nix-maid.url = "github:nix-community/nix-maid";
  };

  den.aspects.my-laptop = {
    includes = [ den.batteries.maid ];
  };
}
```

用户 Aspect 中使用：

```nix
den.aspects.alice = {
  classes = [ "maid" ];
  nix-maid = {
    maid."daily-cleanup" = {
      schedule = "daily";
      script = ''echo "cleaning up"'';
    };
  };
};
```

## 实现简析

```
makeHomeEnv {
  className     = "maid";
  supportedOses = [ "nixos" ];
  optionPath    = "nix-maid";
  getModule     = { host, ... }:
    inputs.nix-maid."${host.class}Modules".default;
  forwardPathFn = { user, ... }: [ "users" "users" user.userName "maid" ];
}
```

- `supportedOses` 限制为 `nixos`，darwin 上不可用
- `forwardPathFn` 路径为 `["users" "users" user.userName "maid"]`，对应 NixOS 的 `users.users.<name>.maid` 选项
- `getModule` 从 `inputs.nix-maid."${host.class}Modules".default` 获取 NixOS 模块
- 缺少 `inputs.nix-maid` 时抛出错误

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.home-manager` | Home Manager 集成电池，同类方案 |
| `den.batteries.hjem` | Hjem 集成电池，同类方案 |
| `den.batteries.define-user` | 与 maid 配合创建完整的 OS + 用户配置 |

## 关联函数

- `den.lib.home-env.makeHomeEnv` — maid 电池的底层实现工厂函数（与 home-manager/hjem 共享）

## 关联文档

- [内置电池](../../../05-内置电池.md) — maid 电池的快速参考
- [Home Manager 集成](../../../06-home-manager集成.md) — maid 集成的详细指南
