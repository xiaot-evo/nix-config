# den.batteries.import-tree

**源文件**: `modules/aspects/batteries/import-tree.nix`

## 用途

递归导入非树状（non-dendritic）`.nix` 文件，根据 `_<class>` 目录名自动分组到对应的 Den 类中。用于从传统 NixOS 配置迁移到 Den 的方面体系时，逐步引入已有的模块文件。

核心能力：

| 能力 | 说明 |
|---|---|
| 按类分组 | `_nixos/` → `nixos` 类，`_homeManager/` → `homeManager` 类 |
| 上下文感知 | `.provides.host`/`.user`/`.home` 自动拼接路径 |
| 递归导入 | 使用 `inputs.import-tree` 库实现完整目录递归 |

## 参数

### 基本调用

```nix
den.batteries.import-tree <root-path>
```

| 参数 | 类型 | 说明 |
|---|---|---|
| `root-path` | `path` 或 `string` | 包含 `_<class>` 子目录的根路径 |

### `.provides` 变体

```nix
den.batteries.import-tree.provides.host  <root-path>  # 自动拼接 /<host.name>
den.batteries.import-tree.provides.user  <root-path>  # 自动拼接 /<user.name>
den.batteries.import-tree.provides.home  <root-path>  # 自动拼接 /<home.name>
```

## 返回值

返回一个方面（aspect），包含按类分组的 `imports`：

```nix
{
  name = "import-tree(<dirName>)";
  meta.provider = [ "den" "batteries" ];
  nixos.imports = [ ... ];          # 从 _nixos/ 导入的模块
  darwin.imports = [ ... ];         # 从 _darwin/ 导入的模块
  homeManager.imports = [ ... ];    # 从 _homeManager/ 导入的模块
  # ... 更多类
}
```

## 目录结构约定

```
<root>/
  _nixos/              # 自动归入 nixos 类
    hardware.nix
    network.nix
  _darwin/             # 自动归入 darwin 类
    foo.nix
  _homeManager/        # 自动归入 homeManager 类
    alice.nix
  _wsl/                # 自动归入 wsl 类
    config.nix
  README.md            # 忽略（非 .nix 文件）
  some-file.nix        # 忽略（不在 _<class> 目录下）
```

**规则**：
- 只导入 `_` 开头的目录（`lib.hasPrefix "_"`）
- 目录名去掉 `_` 前缀即为类名
- 每个 `_<class>` 目录下的所有 `.nix` 文件被 `inputs.import-tree` 递归导入

## 使用示例

### 在主机方面显式导入

```nix
{
  # <repo>/modules/non-dendritic.nix
  den.aspects.my-laptop = {
    includes = [
      (den.batteries.import-tree.provides.host ../non-dendritic)
    ];
    # 自动导入:
    #   ../non-dendritic/my-laptop/_nixos/auto-generated-hardware.nix
    #   ../non-dendritic/my-laptop/_homeManager/me.nix
  };
}
```

目录结构：

```
<repo>/
  modules/
    non-dendritic.nix
  non-dendritic/
    my-laptop/
      _nixos/
        auto-generated-hardware.nix
      _darwin/
        foo.nix
      _homeManager/
        me.nix
```

### 在 schema 级别自动导入

```nix
{
  # 所有主机自动从 ./hosts/<hostName>/ 下加载 _<class> 目录
  den.schema.host.includes = [
    (den.batteries.import-tree.provides.host ./hosts)
  ];

  # 所有用户自动从 ./users/<userName>/ 下加载
  den.schema.user.includes = [
    (den.batteries.import-tree.provides.user ./users)
  ];

  # 所有 home 自动从 ./homes/<homeName>/ 下加载
  den.schema.home.includes = [
    (den.batteries.import-tree.provides.home ./homes)
  ];
}
```

### 自定义导入布局

```nix
{
  den.aspects.my-disko.includes = [
    (den.batteries.import-tree ./disko/)
  ];
}
```

如果 `./disko/` 下有 `_nixos/` 目录，里面的模块会被自动导入到 `nixos` 类。如果也有 `_homeManager/`，也一样导入。

## 实现简析

源文件 91 行，是较为复杂的电池。

### `__functor`：核心导入逻辑

```nix
den.batteries.import-tree.__functor = _: root:
  let
    rootStr = toString root;
    entries = lib.optionalAttrs (builtins.pathExists rootStr) (builtins.readDir rootStr);
    classEntries = lib.filterAttrs (name: type:
      type == "directory" && lib.hasPrefix "_" name) entries;
    aspect = lib.mapAttrs' (dirName: _: {
      name = lib.removePrefix "_" dirName;
      value.imports = [ (inputs.import-tree "${rootStr}/${dirName}") ];
    }) classEntries;
  in
  {
    name = "import-tree(${baseNameOf rootStr})";
    meta.provider = [ "den" "batteries" ];
  } // aspect;
```

执行流程：

1. **扫描目录**：`builtins.readDir rootStr` 读取根目录下的所有条目
2. **过滤 `_<class>` 目录**：`lib.filterAttrs` 只保留以 `_` 开头且为目录的条目
3. **生成方面**：`lib.mapAttrs'` 将每个 `_nixos` → `nixos` 映射为一个 impor ts 条目
4. **递归导入**：`inputs.import-tree "${rootStr}/${dirName}"` 使用 import-tree 工具递归导入所有 `.nix` 文件

### `.provides` 上下文感知变体

```nix
den.batteries.import-tree.provides = {
  host = root: { host, ... }:
    den.batteries.import-tree "${toString root}/${host.name}";
  home = root: { home, ... }:
    den.batteries.import-tree "${toString root}/${home.name}";
  user = root: { user, ... }:
    den.batteries.import-tree "${toString root}/${user.name}";
};
```

每个变体都是返回一个方面函数的函数：

1. `provides.host` 拼接 `<root>/<host.name>`——因此 `hosts/` 目录下需要按 `host.name` 分目录
2. `provides.user` 同理，按用户名称分目录
3. `provides.home` 同理，按 home 名称分目录

这些方面函数被放入对应 schema 的 `includes` 中，Den 在解析方面时会提供 `host`/`user`/`home` 上下文。

### 与 import-tree 输入的关系

`inputs.import-tree` 是一个外部 Nix 库（在 flake 的 `inputs` 中声明），它递归扫描目录并导入所有 `.nix` 文件。本电池只负责将 `import-tree` 的输出按类分组，不自己实现递归导入。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.forward` | 互补工具：import-tree 负责导入，forward 负责分发 |
| `den.batteries.host-aspects` | 复杂场景下两者可能配合使用 |
| `den.batteries.os-class` | 与 import-tree 的类分组概念互补 |
