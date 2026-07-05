# strict 模块

**源文件**: `nix/lib/strict.nix`

## 签名

`(args: attrset) → module`

## 用途

严格模式模块。当启用时，任何未被显式声明的选项设置都会导致错误。这可以帮助捕获打字错误或配置漂移——如果你 `services.ssh.enabel = true` 而不是 `services.ssh.enable = true`，严格模式会在评估时抛出错误而不是静默忽略。

## 参数说明

- `args: attrset` — 标准模块参数（`lib` 等）

## 返回值说明

返回一个设置 `_module.freeformType` 的模块。该 freeformType 的自定义合并函数会在遇到未声明的选项时抛出详细错误。

## 使用示例

```nix
# 在主机配置中启用严格模式
{ den, ... }: {
  imports = [ den.lib.strict ];

  # 以下会导致错误（拼写错误）：
  # services.openssh.enabel = true;
  # → STRICT MODE: Attempted to set the option "enabel" ...
}
```

```nix
# 配合 schema 使用：声明允许的选项
{ den, ... }: {
  imports = [ den.lib.strict ];

  den.schema.host.options.myCustomOption = lib.mkOption {
    type = lib.types.str;
    default = "hello";
  };

  # 现在 myCustomOption 是合法的
  myCustomOption = "world";
}
```

## 错误信息格式

当触发严格模式时，错误信息包含上下文信息：

```
STRICT MODE

Attempted to set the option "<option-name>" in "<config-path>" but no explicit
definition exists. If this wasn't a mistake, disable STRICT mode or configure
an option. e.g.

den.schema.<kind>.options.<option-name> = lib.mkOption { ... };

See https://documentation.example
```

## 实现简析

通过覆盖 `_module.freeformType` 的 `typeMerge` 方法实现。当 freeform 类型尝试合并未知键时，`merge` 函数会抛出异常而不是创建默认值。

`kind` 从路径推导：如果第一个路径段是 `"flake"` 则使用 `"flake"`，否则使用路径的第二段。

______________________________________________________________________

## 关联函数

- `den.schema` — 在 schema 中声明选项使它们成为合法选项
- `modules/config.nix` — 模块系统中严格模式的集成
