# 约束系统

**源文件**: `nix/lib/aspects/fx/constraints.nix`

## 概述

约束系统提供了一种声明性机制来控制方面树中的包含和解析行为。约束在管道的 `gate` 阶段被检查——在分类和发射之前，它们可以导致节点被阻塞、排除或替换。

所有约束构造函数都返回带有 `scope` 字段的记录，指示约束的作用域范围。

---

## `exclude ref`

### 签名
```nix
exclude :: Aspect -> ConstraintRecord
exclude.global :: Aspect -> ConstraintRecord
```

### 用途
创建一个排除约束，从方面树中移除匹配的方面。排除的方面被转换为墓碑（`tombstone`）节点，保留在结果集中但标记为 `meta.excluded = true`。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `ref` | Aspect | 要排除的方面引用（必须有 `name` 和 `meta`） |

### 返回
```nix
{
  type = "exclude";
  identity = "igloo/postgres";  # 方面路径键
  scope = "subtree";             # 或 "global"，基于 .global 调用
}
```

### 作用域语义
- **`subtree`（默认）**：约束仅适用于声明它的子树内的匹配项
- **`global`**：约束适用于整个方面树，无论约束在何处声明

### 示例
```nix
{
  # 在方面中声明排除
  excludes = [
    den.batteries.home-manager  # 排除整个 home-manager 电池
  ];

  # 或在 handleWith 中使用 fx.constraints
  meta.handleWith = [
    (fx.constraints.exclude den.batteries.home-manager)
  ];
}
```

### 门控中的行为

当 `gate` 效果处理排除约束时：

1. 检测到身份匹配
2. 创建墓碑：`identity.tombstone aspect { excludedFrom = owner; }`
3. 发送 `resolve-complete` 记录墓碑（但不在 pathSet 中存储）
4. 如果节点有去重键，发送 `include-unseen` 以避免阻塞后续替换
5. 返回 `{ blocked = true; result = [ tombstone ]; }`

---

## `substitute ref replacement`

### 签名
```nix
substitute :: Aspect -> Aspect -> ConstraintRecord
substitute.global :: Aspect -> Aspect -> ConstraintRecord
```

### 用途
创建一个替换约束，用另一个方面替换树中匹配的方面。原始方面被墓碑标记，替代方面被插入到其位置。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `ref` | Aspect | 要替换的方面引用 |
| `replacement` | Aspect | 替换方面 |

### 返回
```nix
{
  type = "substitute";
  identity = "igloo/postgres";
  replacementName = "newPostgres";
  getReplacement = _: replacement;  # 惰性求值的替换方面
  scope = "subtree";
}
```

### 示例
```nix
{
  meta.handleWith = [
    (fx.constraints.substitute
      den.batteries.home-manager    # 替换
      myCustomHomeManager           # 替代
    )
  ];
}
```

### 门控中的行为

当 `gate` 效果处理替换约束时：

1. 检测到身份匹配
2. 创建墓碑，带有 `replacedBy` 元数据
3. 发送 `resolve-complete` 记录墓碑
4. 发送 `resolve` 效果解析替换方面（可能包含在作用域上下文中）
5. 返回 `{ blocked = true; result = [ tombstone, ...replacementResults ]; }`

```nix
# gate.nix 中的处理链
fx.bind (fx.send "check-constraint" { identity; aspect; }) (decision:
  if decision.action == "substitute" then
    fx.bind (send tombstone) (
      _: fx.bind (fx.send "resolve" {
        aspect = decision.replacement;
        identity = identity.key decision.replacement;
        ctx = param.ctx or { };
      }) (resolved: fx.pure {
        blocked = true;
        result = [ tombstone ] ++ (if builtins.isList resolved then resolved else [ resolved ]);
      })
    )
  ...
)
```

---

## `filterBy pred`

### 签名
```nix
filterBy :: (Aspect -> Bool) -> ConstraintRecord
filterBy.global :: (Aspect -> Bool) -> ConstraintRecord
```

### 用途
创建一个基于谓词的过滤器约束。排除谓词返回 `false` 的方面。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `pred` | Aspect -> Bool | 谓词函数，接收完整方面 attrset，返回是否保留 |

### 返回
```nix
{
  type = "filter";
  predicate = pred;
  scope = "subtree";
}
```

被谓词拒绝的方面得到与显式排除相同的墓碑处理。与 `exclude` 和 `substitute` 不同，过滤器在管道的 `check-constraint` 效果中返回决策而非直接阻塞。

### 示例
```nix
{
  meta.handleWith = [
    (fx.constraints.filterBy (aspect:
      aspect.meta.provider or [] != [ "some" "provider" ]
    ))
  ];
}
```

### 门控中的行为

过滤器约束在 `constraintRegistryHandler` 中被评估。与 `exclude` 和 `substitute` 不同，过滤器在 `check-constraint` 效果中返回一个决策：

 ```nix
# 过滤器决策
if predicate aspect then
  { action = "keep"; }
else
  { action = "exclude"; owner = "filter:<predicate-id>"; };
```

这意味着过滤掉的方面得到与显式排除相同的墓碑处理。

---

## 作用域函数

```nix
scoped = mkFields: {
  __functor = _: args: (mkFields args) // { scope = "subtree"; };
  global = args: (mkFields args) // { scope = "global"; };
};
```

每个约束构造函数都使用 `scoped` 包装器，提供：
- **默认调用**：`fx.constraints.exclude ref` → `scope = "subtree"`
- **`.global` 变体**：`fx.constraints.exclude.global ref` → `scope = "global"`

---

## 约束注册与检查

### 注册（`registerConstraints`）

**源文件**: `nix/lib/aspects/fx/aspect/children.nix`（`registerConstraints` 函数）

在 `compile-static` 期间注册约束：

1. 读取 `aspect.meta.handleWith`（解析处理程序列表）
2. 读取 `aspect.excludes`（便捷的排除列表）
3. 将所有约束归一化为标准记录格式
4. 为每个约束发送 `register-constraint` 效果

### 检查（`check-constraint` 效果）

在 `gate` 期间检查约束：

1. 查找当前作用域的约束注册表
2. 检查身份匹配（`exclude`、`substitute`）
3. 评估谓词（`filter`）
4. 返回决策：`"pass"`、`"exclude"` 或 `"substitute"`

---

## 约束注册表状态

约束存储在每个作用域的状态中：

 ```nix
scopedConstraintRegistry = _: {
  "scope1" = {
    "identity/path" = [ { type = "exclude"; owner = "..."; } ... ];
    ...
  };
};

flatConstraintRegistry = {
  "identity/path" = [ { type = "exclude"; ... } ... ];
};
```

`flatConstraintRegistry` 是跨作用域合并的扁平视图，避免在每个约束检查时进行 O(S) 重建。

---

## 处理程序

**`constraintRegistryHandler`**（来自 `handlers/constraint.nix`）处理：
- `register-constraint`：在注册表中注册约束
- `check-constraint`：检查约束，返回决策

---

## 关联函数

- `fx.pipeline` — 管道编排器，约束在管道的 gate 阶段被检查
- `fx.identity` — 身份路径系统，约束通过身份键定位目标方面
- `fx.includes` — 条件包含辅助，与约束系统的排除/替换是不同的控制流机制
- `fx.key-classification` — 键分类系统，与约束注册的交互
- `den.lib.policy.include` / `den.lib.policy.exclude` — 策略层的包含/排除效果

## 关联文档

- [方面配置指南](../../../04-方面配置指南.md) — 约束在方面元数据中的使用
- [策略系统](../../../07-策略系统.md) — 策略效果的 exclude 效果
