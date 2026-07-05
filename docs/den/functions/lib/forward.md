# forward 模块

**源文件**: `nix/lib/forward.nix`

## 概述

转发方面（Forward Aspect）构建器。转发是将一个类的模块内容传递到另一个类的机制——例如把 `homeManager` 类的内容转发到 `nixos` 类中。转发方面通过 `meta.__forward` 标记，由管道中的 `compile-forward` 处理器处理。

______________________________________________________________________

## den.lib.forward.forwardItem

**签名**: `(config: attrset) → aspect`

### 用途

构建一个转发方面。指定源类、目标类、转发路径和可选的门控/适配器逻辑。

### 参数说明

- `config: attrset` — 转发配置：
  - `item: any` — 要转发的条目
  - `fromClass: (item → string)` — 源类名（从条目中计算）
  - `fromAspect: (item → aspect)（可选）` — 源方面
  - `fromCtx: (item → ctx)（可选）` — 源上下文
  - `intoClass: (item → string)（可选）` — 目标类名（默认通过 `den.classes` 注册的 `forwardTo`）
  - `intoPath: (item → [string])（可选）` — 目标路径
  - `guard: (ctx → bool 或 (ctx → (item → attrs)))（可选）` — 条件守卫
  - `adaptArgs: (ctx → args)（可选）` — 参数适配器
  - `adapterModule: module 或 (item → module)（可选）` — 适配器模块
  - `mapModule: (item → module → module)（可选）` — 模块映射函数
  - `evalConfig: bool（可选）` — 是否评估配置（默认 `false`）

### 返回值说明

返回一个包含 `meta.__forward` 的方面 attrset，供管道中的 `compile-forward` 处理器消费。

### 使用示例

```nix
# 基本转发：将 homeManager 内容转发到 nixos
den.lib.forward.forwardItem {
  item = true;
  fromClass = _: "homeManager";
  intoClass = _: "nixos";
  fromAspect = _: {
    homeManager.programs.git.enable = true;
  };
}
```

```nix
# 带用户上下文的转发
den.lib.forward.forwardItem {
  item = true;
  fromClass = _: "homeManager";
  intoClass = _: "nixos";
  intoPath = _: [ "users" "tux" ];
  fromCtx = _: { host = { name = "igloo"; }; user = { name = "tux"; }; };
  fromAspect = _: den.lib.resolveEntity "user" {
    host = { name = "igloo"; };
    user = { name = "tux"; classes = [ "homeManager" ]; };
  };
}
```

### 实现简析

构建一个复杂 `meta.__forward` attrset，包含源类、目标类、路径、守卫函数、适配器等。转发方面本身不含直接内容（`includes = []`），仅携带转发元数据。

______________________________________________________________________

## den.lib.forward.forwardEach

**签名**: `(fwd: attrset) → aspect`

### 用途

批量转发——对 `each` 列表中的每个条目调用 `forwardItem`。

### 参数说明

- `fwd: attrset` — 转发配置，额外需要：
  - `each: [any]` — 要转发的条目列表
  - 其余与 `forwardItem` 相同

### 返回值说明

返回一个方面，其 `includes` 包含每个条目的转发方面。

### 使用示例

```nix
den.lib.forward.forwardEach {
  each = [
    { user = "alice"; classes = [ "homeManager" ]; }
    { user = "bob"; classes = [ "homeManager" ]; }
  ];
  fromClass = _: "homeManager";
  intoClass = _: "nixos";
  intoPath = item: [ "users" item.user ];
  fromAspect = item: den.lib.resolveEntity "user" {
    host = { name = "igloo"; };
    user = item;
  };
}
```

### 实现简析

对 `each` 列表执行 `map`，将 `fwd` 参数与每个 `item` 合并后传递给 `forwardItem`。

______________________________________________________________________

## 关联函数

- `den.lib.resolveEntity` — 创建转发的目标实体
- `den.batteries.forward` — 高级转发电池，底层使用 `forwardItem`
- `den.lib.policy.route` — Tier 1 路由，比 forward 更轻量
