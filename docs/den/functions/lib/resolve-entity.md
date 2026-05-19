# resolveEntity 函数

**源文件**: `nix/lib/resolve-entity.nix`

## 签名

`(name: string, ctx: attrset) → aspect`

## 用途

为实体（主机、用户、家庭等）创建根方面（root aspect）。每个实体的 `.aspect` 入口点通过此函数生成，包含实体上下文的作用域处理器和自我提供（self-provide）逻辑。

## 参数说明

- `name: string` — 实体类型名称（如 `"host"`、`"user"`、`"home"`、`"default"`）
- `ctx: attrset` — 实体上下文（如 `{ host = { ... }; user = { ... }; }`）

## 返回值说明

返回一个方面 attrset，包含：
- `name` — 实体名称
- `meta.handleWith` — 处理方式（`null`）
- `meta.provider` — 提供者路径（`[]`）
- `excludes` — 从 schema 继承的排除项
- `includes` — 自我提供（self-provide）+ schema 继承的 includes
- `__entityKind` — 实体类型
- `__scopeHandlers` — 作用域处理器（常量处理器，携带增强上下文）

## 使用示例

```nix
# 手动创建用户实体根方面
den.lib.resolveEntity "user" {
  host = { name = "igloo"; class = "nixos"; };
  user = { name = "tux"; classes = [ "homeManager" ]; };
}
# → {
#   name = "user";
#   meta = { handleWith = null; provider = []; };
#   excludes = [];
#   includes = [
#     # 自提供：解析 user.aspect
#     { __fn = c: c.user.aspect; __args = { user = false; }; ... }
#     # schema includes
#   ];
#   __entityKind = "user";
#   __scopeHandlers = { ... };  # 携带增强上下文
# }
```

```nix
# "default" 实体类型特殊处理
den.lib.resolveEntity "default" { }
```

## 实现简析

1. 读取 `den.schema.${name}` 获取 schema 级别的 includes/excludes/collisionPolicy
2. 提取相关实体绑定（如 `home.host`、`home.user`）
3. 创建常量处理器携带增强上下文
4. 对 schema 实体类型（host/user/home 等）添加自提供（`__fn = c: c.${name}.aspect`）
5. "default" 类型特殊处理，提供 `den.default` 作为自提供

## 关联函数

- `den.lib.aspects.resolve` — 后续解析根方面
- `den.lib.forward.forwardItem` — 转发时引用 `resolveEntity` 创建目标实体
- `den.lib.schemaUtil.schemaEntityKinds` — 确定哪些 schema 类型获得自提供
