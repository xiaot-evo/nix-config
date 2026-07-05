# den.batteries.unfree

**源文件**: `modules/aspects/batteries/unfree/unfree.nix`

## 用途

类通用的参数化方面（parametrized aspect），按包名启用不自由（unfree）软件包。可在 Host、User、Home 任意上下文中使用。

关键行为：

- 签名：`den.batteries.unfree [ "pkg1" "pkg2" ... ]`
- 使用参数化方面（`__args = { class = true; host = true; }`）
- 对每种有效类（`nixos`/`darwin`/`homeManager`）动态生成 `{class}.unfree.packages`
- HM 模式下，同时向 OS 类发出模块，确保 `nixpkgs.config.allowUnfreePredicate` 正确覆盖

## 使用示例

```nix
# Host 层面启用
den.aspects.my-laptop = {
  includes = [
    (den.batteries.unfree [ "unrar" "steam" "vscode" ])
  ];
};
```

```nix
# User 层面启用
den.aspects.alice = {
  includes = [
    (den.batteries.unfree [ "discord" "spotify" ])
  ];
};
```

## 实现简析

```
__functor = _self: allowed-names: {
  name = "unfree(pkg1,pkg2,...)";
  __fn = { class, host ? null, ... }: let
    validClasses = [ "nixos" "darwin" "homeManager" ];
    classModule = lib.optionalAttrs (builtins.elem class validClasses) {
      ${class}.unfree.packages = allowed-names;
    };
    # HM 或非标准类时也注入 OS 模块
    hostModule = lib.optionalAttrs (
      (class == "homeManager" || !builtins.elem class validClasses)
      && host != null
      && builtins.elem host.class validClasses
    ) { ${host.class}.unfree.packages = allowed-names; };
  in classModule // hostModule;
  __args = { class = true; host = true; };
};
```

- `__functor` 使 `den.batteries.unfree` 可调用，返回一个方面（aspect）
- `__args` 声明需要 `class` 和 `host` 参数，Den 框架在解析时自动注入
- `classModule` 为当前解析的类注入 `unfree.packages`
- `hostModule` 在 HM 或 user 类中额外向 Host OS 类注入，确保 `allowUnfreePredicate` 在系统层面也能捕获这些包名

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.insecure` | 同类模式：按包名启用不安全包，实现结构相同 |
| `den.batteries.flake-scope` | 在管道函数中提供 `lib`/`inputs`/`den` 上下文 |

## 关联文档

- [内置电池](../../../05-%E5%86%85%E7%BD%AE%E7%94%B5%E6%B1%A0.md) — unfree 电池的快速参考和完整示例
