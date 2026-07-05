# den-brackets（角度括号语法）模块

**源文件**: `nix/lib/den-brackets.nix`

## 概述

实现了 `<den/X/Y>` 角度括号语法。这是一个字符串查找/解析机制，允许在 Nix 代码中用简洁的路径引用方面、电池、命名空间等。

该模块作为 `den.lib.__findFile` 导出，是 `builtins.findFile` 的钩子函数。

## 解析逻辑

### 签名

`(_nixPath: [string], name: string) → any`

### 解析路径

输入 `<den/X/Y>` 会触发解析：

1. **`<den/电池名>`** → 如果 `X` 是 `den.batteries` 中的提供者（如 `forward`、`import-tree`），直接返回该电池
1. **`<den/电池名/Y>`** → 返回电池的 `provides.Y` 子路径
1. **`<den/X/Y>`** → 从 `config.den.X.Y` 读取
1. **`<方面名>`** → 在 `den.aspects` 中查找
1. **`<方面名/Y>`** → 返回方面的 `provides.Y` 或直接子键 `Y`
1. **`<命名空间/X>`** → 在 `den.ful.<命名空间>` 中查找

### 子路径解析的 provides 兼容

直接键优先于 `provides` 路径。仅当直接键不存在时回退到 `provides`，并发出弃用警告。

### 使用示例

```nix
# 在模块声明中引用方面
{ den, ... }: {
  imports = [
    <den/batteries/hostname>
    den.batteries.hostname  # 等效
  ];
}
```

```nix
# 在 includes 中使用
{ den, ... }: {
  den.aspects.igloo.includes = [
    <den/batteries/hostname>
    <my-app/nixos>
  ];
}
```

## 实现简析

1. 将角度括号内容中的 `/` 替换为 `.`（`<den/batteries/hostname>` → `"den.batteries.hostname"`）
1. 按点号分割路径
1. 遍历 `findAspect`：
   - 如果首段是 `"den"`，检查下一段是否是电池提供者 → 通过 `den.batteries` 路由
   - 否则从 `config.den` 读取路径
   - 如果首段是方面名 → 在 `den.aspects` 中查找
   - 如果首段是命名空间 → 在 `den.ful` 中查找
1. `__provider` 标记：裸 attrset 结果会被标记 `__provider` 路径，以便管道计算稳定身份

### 为什么需要 `__provider` 标记？

转发的内容包装器是裸 attrset，缺少 `__provider`。没有这个标记，它们会获得匿名身份，去重失败。

______________________________________________________________________

## 关联函数

- `den.lib.namespace` — 命名空间导入（也影响角度括号解析的范围）
