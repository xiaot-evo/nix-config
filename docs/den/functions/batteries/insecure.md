# den.batteries.insecure

**源文件**: `modules/aspects/batteries/insecure/insecure.nix`

## 用途

类通用的参数化方面，按包名+版本启用不安全（insecure）软件包。与 `den.batteries.unfree` 结构相同，但操作为 `permittedInsecurePackages`。

关键行为：

- 签名：`den.batteries.insecure [ "pkg-1.0.0" "pkg-2.0.0" ... ]`
- 使用参数化方面（`__args = { class = true; host = true; }`）
- 对每种有效类（`nixos`/`darwin`/`homeManager`）动态生成 `{class}.permittedInsecurePackages.packages`
- HM 模式下，同时向 OS 类发出模块，确保 `nixpkgs.config.permittedInsecurePackages` 正确覆盖

## 使用示例

```nix
# Host 层面启用不安全包
den.aspects.my-laptop = {
  includes = [
    (den.batteries.insecure [ "openssl-1.1.1" "python-2.7.18" ])
  ];
};
```

```nix
# User 层面启用
den.aspects.alice = {
  includes = [
    (den.batteries.insecure [ "nodejs-12.22.12" ])
  ];
};
```

## 实现简析

```
__functor = _self: allowed-names: {
  name = "insecure(pkg1,pkg2,...)";
  __fn = { class, host ? null, ... }: let
    validClasses = [ "nixos" "darwin" "homeManager" ];
    classModule = lib.optionalAttrs (builtins.elem class validClasses) {
      ${class}.permittedInsecurePackages.packages = allowed-names;
    };
    hostModule = lib.optionalAttrs (
      (class == "homeManager" || !builtins.elem class validClasses)
      && host != null
      && builtins.elem host.class validClasses
    ) { ${host.class}.permittedInsecurePackages.packages = allowed-names; };
  in classModule // hostModule;
  __args = { class = true; host = true; };
};
```

- 与 `den.batteries.unfree` 实现几乎相同，区别在于注入的是 `permittedInsecurePackages.packages` 而非 `unfree.packages`
- `classModule` 为当前类注入白名单
- `hostModule` 为 HM 或 user 类场景额外向 OS 类注入，确保 `nixpkgs.config.permittedInsecurePackages` 在构建时生效

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.unfree` | 同类模式：按包名启用不自由包，实现结构相同 |
| `den.batteries.flake-scope` | 在管道函数中提供 `lib`/`inputs`/`den` 上下文 |

## 关联文档

- [内置电池](../../../05-%E5%86%85%E7%BD%AE%E7%94%B5%E6%B1%A0.md) — insecure 电池的快速参考
