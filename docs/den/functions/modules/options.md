# NixOS 模块选项

**源文件**: `modules/options.nix`、`modules/aspects.nix`、`modules/config.nix`、`nix/nixModule/lib.nix`、`nix/nixModule/pipes.nix`、`nix/nixModule/policies.nix`

## 概述

Den 通过 `modules/options.nix`（及辅助模块）注册所有顶层 `den.*` 选项。本页列出所有选项及其类型、默认值。

---

## den.hosts — 主机声明

**类型**: 自动从 `lib/entities/host.nix` 推断

**默认值**: `{}`

**文件**: `modules/options.nix`（导入 `lib/entities/host.nix` 的 `hostsOption`）

声明 NixOS/Darwin 主机：

```nix
den.hosts."x86_64-linux".igloo = {
  hostName = "igloo";
  nixos.services.ssh.enable = true;
};
```

详见 [entities/host.md](../lib/entities/host.md)。

---

## den.homes — 家庭声明

**类型**: 自动从 `lib/entities/home.nix` 推断

**默认值**: `{}`

声明独立 Home Manager 配置：

```nix
den.homes."x86_64-linux"."alice@igloo" = {
  homeManager.programs.git.enable = true;
};
```

详见 [entities/home.md](../lib/entities/home.md)。

---

## den.aspects — 方面定义

**类型**: `aspectsType`（来自 `lib/aspects/types.nix`）

**默认值**: `{}`

**文件**: `nix/nixModule/aspects.nix`

定义可组合的配置单元：

```nix
den.aspects.igloo = {
  nixos.networking.hostName = "igloo";
  homeManager.programs.git.enable = true;
};
```

详见 [aspects-definition.md](aspects-definition.md)。

---

## den.policies — 策略定义

**类型**: `attrsOf policyType`

**默认值**: `{}`

**文件**: `nix/nixModule/policies.nix`

定义上下文驱动的路由策略：

```nix
den.policies.host-to-users = { host, ... }: [
  (den.lib.policy.resolve.shared { inherit user; })
];
```

详见 [policies.md](policies.md)。

---

## den.classes — 类注册

**类型**: `lazyAttrsOf classSchemaType`

**默认值**:

```nix
{
  nixos.description = "NixOS system configuration";
  darwin.description = "nix-darwin system configuration";
}
```

**文件**: `modules/options.nix`

注册 Nix 配置输出类别。每个类有 `description` 和可选的 `forwardTo`：

```nix
den.classes.homeManager.description = "Home Manager user environment";
```

---

## den.quirks — 管道声明

**类型**: `lazyAttrsOf pipeSchemaType`

**默认值**: `{}`

**文件**: `modules/options.nix`（`den.quirks`）和 `nix/nixModule/pipes.nix`（`den.pipes`）

声明命名数据路由，用于结构化的管道流。与 `den.classes` 共享名称检查：

```nix
den.quirks.my-pipe.description = "Cross-host data pipe";
```

`den.quirks` 和 `den.classes` 的键不可重叠。

---

## den.schema — 模式扩展

**类型**: 自由形式 `lazyAttrsOf schemaEntryType`

**默认值**:

```nix
{
  conf = { };
  fleet = { };
  host.imports = [ den.schema.conf ];
  user.imports = [ den.schema.conf ];
  home.imports = [ den.schema.conf ];
}
```

实体模式的自由模块。可为每个实体类型定义 `includes`、`excludes` 和结构化模块内容：

```nix
den.schema.host.includes = [ den.batteries.hostname ];
den.schema.user.includes = [ myUserModule ];
```

### schemaEntryType

特殊合并类型，支持：
- `includes`: 要包含的策略/方面列表
- `excludes`: 要排除的策略/方面列表
- 自动计算 `id_hash`: 实体身份哈希
- 自动计算 `resolved`: 解析后的方面
- `collisionPolicy`: 冲突处理策略

---

## den.batteries — 电池声明

**类型**: `attrsOf raw`

**默认值**: `{}`

**文件**: `nix/nixModule/default.nix`

预构建的可复用方面集合：

```nix
den.batteries.hostname = { ... };
den.batteries.define-user = { ... };
```

详见 [batteries/README.md](../batteries/README.md)。

---

## den.default — 默认方面

**类型**: `submodule { freeformType = attrsOf anything; }`

**默认值**: `{}`

**文件**: `nix/nixModule/default.nix`

对所有实体应用的默认方面。在实体自身的方面之前合并：

```nix
den.default = {
  includes = [
    den.batteries.hostname
    den.batteries.define-user
  ];
};
```

---

## den.config — 全局配置

**类型**: `submodule`

**文件**: `modules/config.nix`

### den.config.classModuleCollisionPolicy

- **类型**: `enum ["error" "class-wins" "den-wins"]`
- **默认值**: `"error"`
- **说明**: 处理 Den 上下文参数和模块系统参数之间的冲突。

---

## den.systems — 系统列表

**类型**: `listOf str`

**默认值**: 来自 `flame.nix`（`modules/outputs.nix` 或其他位置推导）

Flake 支持的系统架构列表：

```nix
den.systems = ["x86_64-linux" "aarch64-linux"];
```

---

## den.lib — 库函数

**类型**: `submodule { freeformType = lazyAttrsOf unspecified; }`

**默认值**: 来自 `nix/lib/default.nix`

**文件**: `nix/nixModule/lib.nix`

```nix
den.lib.aspects.resolve
den.lib.diag.toMermaid
den.lib.policy.resolve
# ... 等
```

内部选项，只读。

---

## den.ful — 命名空间

**类型**: `attrsOf namespaceType`

**默认值**: `{}`

**文件**: `modules/aspects.nix`

内部方面树，用于命名空间管理：

```nix
den.ful.my-namespace = { ... };
```

也通过 `flake.denful` 暴露给 flake 输出。

---

## 关联

- **`modules/aspects.nix`**: `den.ful` 和 `den.aspects` 选项
- **`modules/config.nix`**: `den.config` 选项
- **`nix/nixModule/`**: `aspects.nix`、`lib.nix`、`pipes.nix`、`policies.nix`、`default.nix`
- **`lib/entities/`**: `host.nix`、`home.nix` 提供 hosts/homes 类型
