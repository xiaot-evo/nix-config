# policy（策略效果）模块

**源文件**: `nix/lib/policy-effects.nix`

## 概述

策略效果构造器。策略函数返回这些效果描述符的列表，管道根据 `__policyEffect` 分派到对应的效果处理器。

每一种效果构造器代表一种可以在策略中发出的信号：创建新作用域、包含/排除方面、路由内容、注入模块等。

______________________________________________________________________

## den.lib.policy.resolve

**签名**: `(bindings: attrset) → effect`

### 用途

创建新的上下文作用域（扇出）。每个 `resolve` 创建一个并行的分支——一个带有新绑定的兄弟上下文。`resolve {}`（空绑定）是无操作的。

### 参数说明

- `bindings: attrset` — 注入新上下文的绑定（如 `{ user = { ... }; }`）

### 返回值说明

`{ __policyEffect = "resolve"; value = bindings; ... }` 格式的效果描述符。

### 使用示例

```nix
# 为每个用户创建新的解析分支
{ host, ... }: map (user:
  den.lib.policy.resolve { inherit user; }
) (lib.attrValues host.users)
```

______________________________________________________________________

## den.lib.policy.resolve.to

**签名**: `(kind: string, bindings: attrset) → effect`

### 用途

解析到特定的实体类型。比普通的 `resolve` 多一个 `__targetKind` 标记，用于更精确的路由控制。

### 参数说明

- `kind: string` — 目标实体类型（如 `"user"`、`"home"`）
- `bindings: attrset` — 上下文绑定

### 使用示例

```nix
den.lib.policy.resolve.to "user" { user = someUser; }
```

______________________________________________________________________

## den.lib.policy.resolve.shared

**签名**: `(bindings: attrset) → effect`

### 用途

共享扇出（非隔离解析）。普通的 `resolve` 创建隔离分支，`shared` 创建共享分支。共享解析不会隔离上下文——子方面共享父作用域的部分。

### 使用示例

```nix
den.lib.policy.resolve.shared { user = someUser; }
# 或指定类型
den.lib.policy.resolve.shared.to "user" { user = someUser; }
```

______________________________________________________________________

## den.lib.policy.include

**签名**: `(aspect: any) → effect`

### 用途

将一个方面注入当前解析上下文。接受方面引用和内联 attrset（自动转换为匿名方面）。

### 参数说明

- `aspect: any` — 方面引用、内联 attrset 或模块函数

### 返回值说明

`{ __policyEffect = "include"; value = aspect; }`

### 使用示例

```nix
# 包含一个模块
den.lib.policy.include { nixos.services.openssh.enable = true; }

# 包含一个命名方面
den.lib.policy.include den.batteries.hostname
```

______________________________________________________________________

## den.lib.policy.exclude

**签名**: `(aspect: any) → effect`

### 用途

从当前解析树中移除/门控一个方面。上下文匹配——适用于匹配策略签名的所有上下文。

### 参数说明

- `aspect: any` — 要排除的方面引用

### 返回值说明

`{ __policyEffect = "exclude"; value = aspect; }`

### 使用示例

```nix
# 排除某个方面
den.lib.policy.exclude den.batteries.unfree
```

______________________________________________________________________

## den.lib.policy.route

**签名**: `(spec: attrset) → effect`

### 用途

将类或 quirk 的内容从一个作用域分区路由到目标类。Tier 1 分发机制——在大多数常见场景中替代 `den.batteries.forward`。

### 参数说明

- `spec: attrset` — 路由规范

### 返回值说明

`{ __policyEffect = "route"; value = spec; }`

### 使用示例

```nix
den.lib.policy.route {
  fromClass = "homeManager";
  toPath = [ "users" "tux" ];
}
```

______________________________________________________________________

## den.lib.policy.instantiate

**签名**: `(spec: attrset) → effect`

### 用途

请求在管道后期实例化实体的类内容。实体需要携带 `instantiate`、`intoAttr`、`mainModule` 元数据。

### 参数说明

- `spec: attrset` — 实例化规范

### 返回值说明

`{ __policyEffect = "instantiate"; value = spec; }`

______________________________________________________________________

## den.lib.policy.provide

**签名**: `(spec: attrset) → effect`

### 用途

直接向目标类注入一个新模块。与 `route`（移动现有管道内容）不同，`provide` 注入之前不存在的新内容。

### 参数说明

- `spec: attrset` — `{ class, module, path? }`

### 返回值说明

`{ __policyEffect = "provide"; value = spec; }`

### 使用示例

```nix
den.lib.policy.provide {
  class = "nixos";
  module = { services.nginx.enable = true; };
}
```

______________________________________________________________________

## den.lib.policy.pipe.from

**签名**: `(pipeName: string | ref, stages: [stage]) → effect`

### 用途

为指定的 quirk/pipe 附加转换阶段。支持多种阶段类型：`filter`、`transform`、`fold`、`append`、`for`、`to`、`as` 等。

### 参数说明

- `pipeName: string 或 ref` — pipe 名称或引用
- `stages: [stage]` — 阶段描述符列表

### 返回值说明

`{ __policyEffect = "pipe"; value = { pipeName, stages }; }`

### 使用示例

```nix
den.lib.policy.pipe.from "my-quirk" [
  (den.lib.policy.pipe.filter (item: item.enable))
  (den.lib.policy.pipe.transform (item: item.config))
]
```

______________________________________________________________________

## den.lib.policy.pipelineOnly

**签名**: `(value: function 或 attrs) → attrs`

### 用途

标记一个值只能由管道产生（不能来自模块系统）。设置 `collisionPolicy = "class-wins"`，当值与模块系统的同名参数冲突时，模块系统的值胜出。

### 使用示例

```nix
den.lib.policy.pipelineOnly ({ host, ... }: { ... })
```

______________________________________________________________________

## den.lib.policy.for

**签名**: `(entityOrEntities: entity 或 [entity], policiesOrSingle: policy 或 [policy]) → policy 或 [policy]`

### 用途

包装一个或多个策略，使其只在特定实体上下文中触发。使用 `id_hash` 进行可靠的实体身份匹配。

### 参数说明

- `entityOrEntities` — 目标实体（或实体列表）
- `policiesOrSingle` — 要包装的策略（或列表）

### 返回值说明

包装后的策略函数。

### 使用示例

```nix
den.lib.policy.for hostA (den.lib.policy.include someAspect)
# → 只在 hostA 上下文中触发的策略
```

______________________________________________________________________

## den.lib.policy.when

**签名**: `(predicate: function, policiesOrSingle: any) → aspect 或 policy`

### 用途

条件门控。当谓词为 true 时触发。对于内联方面，创建条件方面（`meta.guard`）；对于策略，创建条件策略。

### 参数说明

- `predicate: (ctx → bool)` — 谓词函数
- `policiesOrSingle` — 要包装的值

### 使用示例

```nix
den.lib.policy.when
  (ctx: ctx.host.name == "igloo")
  (den.lib.policy.include iglooOnlyModule)
```

______________________________________________________________________

## den.lib.policy.mkPolicy

**签名**: `(name: string, fn: function) → policyRecord`

### 用途

创建一个命名的策略记录，可用于 `includes` 列表。策略记录包含 `__isPolicy = true`、`name` 和 `fn`。

### 参数说明

- `name: string` — 策略名
- `fn: (ctx → [effect])` — 策略函数

### 返回值说明

`{ __isPolicy = true; name = name; fn = fn; }`

### 使用示例

```nix
den.default.includes = [
  (den.lib.policy.mkPolicy "host-guards" ({ host, ... }: [
    den.lib.policy.include {
      nixos.hostName = host.name;
    }
  ]))
];
```

______________________________________________________________________

## 关联函数

- `den.lib.policyInspect.inspect` — 检查策略匹配情况
- `den.lib.aspects.fx.policy` — 策略效果的分派管道
