# policyInspect 模块

**源文件**: `nix/lib/policy-inspect.nix`

## 概述

轻量级策略检查工具。直接调用解析函数，不执行完整管道。主要用于调试——回答"为什么主机 X 得到了这个模块？"之类的问题。

---

## den.lib.policyInspect.inspect

**签名**: `({ kind, context }) → { [policyName]: info }`

### 用途

检查给定实体类型和上下文时，哪些策略会触发以及它们的路由信息。不执行完整管道，只调用策略函数解析效果描述符。

### 参数说明

- `kind: string` — 实体类型（如 `"host"`、`"user"`）
- `context: attrset` — 检查上下文（包含 `host`、`user` 等绑定）

### 返回值说明

返回一个 attrset，键为匹配的策略名，值为检查结果：
```nix
{
  <policyName> = {
    targetKey = string;   # 目标键
    targets = [effect];   # resolve 效果列表
    from = string;        # 源实体类型
    to = string;          # 目标实体类型
    as = string;          # 别名（目前固定 ""）
    routing = "sibling" | "child";  # 路由类型
  };
}
```

### 使用示例

```nix
# 检查主机上下文中的策略
den.lib.policyInspect.inspect {
  kind = "host";
  context = {
    host = { name = "igloo"; class = "nixos"; };
    user = { name = "tux"; classes = [ "homeManager" ]; };
  };
}
# → {
#   "host-to-homeManager-users" = {
#     targetKey = "user";
#     targets = [ { __policyEffect = "resolve"; value = { user = {...}; }; } ];
#     from = "host";
#     to = "user";
#     routing = "child";
#   };
# }
```

```nix
# 不匹配的上下文
den.lib.policyInspect.inspect {
  kind = "host";
  context = { };  # 没有 host 绑定
}
# → {}  （没有策略匹配）
```

### 实现简析

1. 从 `den.policies` 读取所有注册的策略
2. 使用 `resolveArgsSatisfied` 过滤匹配上下文的策略
3. 对每个匹配策略，调用它并解析效果描述符
4. 从 resolve 效果推断目标类型（通过 `__targetKind` 或查找 schema 实体键）
5. 判断路由类型：`from == to → "sibling"`，否则 `"child"`

### 辅助函数

`unwrapPolicy` — 将策略注册条目解包为原始函数（处理 `__isPolicy` 记录）

---

## 关联函数

- `den.lib.synthesizePolicies.resolveArgsSatisfied` — 策略匹配的核心逻辑
- `den.lib.policy` — 策略效果构造器
