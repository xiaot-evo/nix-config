# namespace 模块

**源文件**: `nix/lib/namespace.nix`

## 签名

`(name: string, sources: [any]) → module`

## 用途

导入外部 Denful 命名空间。允许将一个或多个外部 Den flake 的 `denful.${name}` 输出导入到当前 flake 的 `den.ful.${name}` 下，并通过简短的别名访问。

## 参数说明

- `name: string` — 命名空间名称（如 `"den"`、`"infra"`）
- `sources: [any]` — 源输入列表（通常是 `inputs` 中的 flake）。列表中的元素可以是 attrset（直接从其 `denful.${name}` 属性读取）或 `true`（表示将当前命名空间作为 flake 输出）。

## 返回值说明

返回一个 NixOS 模块，该模块：
1. 导入源模块（将外部 denful 数据注入 `config.den.ful.${name}`）
2. 创建别名选项（`${name}` → `den.ful.${name}`）
3. 如果 `sources` 中包含 `true`，将本地命名空间输出到 `flake.denful.${name}`
4. 合并外部类的注册（`den.classes`）
5. 将 `${name}` 注入 `_module.args` 以便在其他模块中直接使用

## 使用示例

```nix
# 基本用法：导入标准 den 命名空间
{
  imports = [
    (den.lib.namespace "den" [
      inputs.den  # 从 inputs.den 读取 denful.den
    ])
  ];
}
# 之后可以用 den.aspects、den.batteries 等访问

# 多源导入
(den.lib.namespace "infra" [
  inputs.infra-flake
  inputs.infra-backup
  true  # 同时导出本地命名空间
])
```

```nix
# 在模板中的实际用法
# modules/namespace.nix
{ inputs, ... }:
{
  imports = [
    (den.lib.namespace "den" [ inputs.den ])
  ];
}
```

## 实现简析

1. 从每个源输入中提取 `denful.${name}`（使用 `lib.getAttrFromPath`）
2. 去除 `_` 和 `__functor` 别名（防止重导入时重复）
3. 创建别名选项模块（`${name}` → `den.ful.${name}`）
4. 如果 `sources` 包含 `true`，创建输出模块将本地内容写入 `flake.denful.${name}`
5. 合并外部命名空间的 `classes` 注册到 `den.classes`
6. 将 `${name}` 注入 `_module.args` 实现直接访问

### 为什么需要去除别名？

外部 denful 的 `_` → `provides` 别名在重导入时会导致重复的 `includes`（因为 `listOf` 选项会合并重复条目）。去除别名后只保留 `provides` 作为规范键。

---

## 关联函数

- `den-brackets.nix` — `<den/X/Y>` 语法也解析命名空间路径
- `den.lib.types` / `den.lib.nsTypes` — 命名空间类型定义
