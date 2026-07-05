# hjem (自动注册模块)

**源文件**: `modules/aspects/batteries/hjem.nix`

## 用途

Hjem（Rust 实现的 Home Manager 替代方案）集成电池。与 `home-manager` (自动注册模块) 类似，但将用户配置转发到 Hjem 模块系统。

关键行为：

- 注册 `hjem` 类，描述为 "Hjem user environment"
- 通过 `den.lib.home-env.makeHomeEnv` 构建
- `className = "hjem"`，`optionPath = "hjem"`
- 自动转发到 `hjem.users.<userName>`
- 需要 `inputs.hjem` flake 输入；不存在则抛出错误

## 使用示例

```nix
{
  # 在 flake 中引入 hjem 输入
  inputs = {
    hjem.url = "github.com/feel-co/hjem";
  };

  # Host aspect — hjem 模块已自动注册，无需在 includes 中手动引入
  den.aspects.my-laptop = {
    # 无需 includes = [ den.batteries.hjem ]，本模块已自动注册到 den.schema.host.includes
  };
}
```

用户 Aspect 中使用：

```nix
den.aspects.alice = {
  classes = [ "hjem" ];
  hjem = {
    programs.bash.enable = true;
  };
};
```

## 实现简析

```
makeHomeEnv {
  className  = "hjem";
  optionPath = "hjem";
  getModule  = { host, ... }:
    inputs.hjem."${host.class}Modules".default;
  forwardPathFn = { user, ... }: [ "hjem" "users" user.userName ];
}
```

- 与 `home-manager` 电池结构一致，通过 `makeHomeEnv` 工厂函数生成 Host→User 路由
- `forwardPathFn` 将用户配置写入 `hjem.users.<userName>`
- `getModule` 从 `inputs.hjem."${host.class}Modules".default` 获取对应 OS 的 Hjem 模块（如 `nixosModules.default`）
- 缺少 `inputs.hjem` 时抛出错误提示

## 关联电池

| 电池 | 关系 |
|---|---|
| `home-manager` (自动注册模块) | Home Manager 集成模块，同类方案 |
| `maid` (自动注册模块) | Nix-Maid 集成模块，同类方案 |
| `den.batteries.define-user` | 与 hjem 配合创建完整的 OS + 用户配置 |

## 关联函数

- `den.lib.home-env.makeHomeEnv` — hjem 电池的底层实现工厂函数（与 home-manager 共享）

## 关联文档

- [内置电池](../../../05-%E5%86%85%E7%BD%AE%E7%94%B5%E6%B1%A0.md) — hjem 电池的快速参考
- [Home Manager 集成](../../../06-home-manager%E9%9B%86%E6%88%90.md) — hjem 集成的详细指南和多家庭环境示例
