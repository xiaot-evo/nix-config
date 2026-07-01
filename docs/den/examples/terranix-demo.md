# terranix-demo 模板

**Terraform 集成** — 展示如何使用 Den 的方面系统生成 Terraform/OpenTofu 配置（通过 terranix），在 Den 实体中用自定义类管理基础设施资源。

## 用途

- 在 Den 中一体化管理 NixOS 配置 + Terraform 资源
- 学习自定义类（`terranix` 类）和 `den.lib.policy.instantiate`
- 作为跨域（系统配置 + 基础设施即代码）融合的参考实现

## 目录结构

```
templates/terranix-demo/
├── flake.nix              # 入口（flake-parts + import-tree）
├── flake.lock
└── modules/
    ├── den.nix             # 实体拓扑 + 默认包含
    ├── flake-parts.nix     # flake-parts 系统
    ├── host-schema.nix     # 主机 schema 扩展（server-type、region、image）
    ├── terranix.nix        # 核心：terranix 集成层
    └── aspects/
        ├── provider.nix    # hcloud provider 方面
        ├── server.nix      # 参数化 server 资源方面
        └── hosts/
            ├── web-1.nix   # web-1 NixOS 方面（nginx）
            └── web-2.nix   # web-2 NixOS 方面（nginx）
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `nixpkgs` | nixpkgs-unstable | 包集合 |
| `den` | path:../.. | Den 框架（本地） |
| `import-tree` | github:vic/import-tree | 递归导入 |
| `flake-parts` | github:hercules-ci/flake-parts | perSystem |
| `home-manager` | github:nix-community/home-manager | 用户环境 |
| `terranix` | github:terranix/terranix | Terraform JSON 生成 |
| `files` | github:mightyiam/files | 文件处理 |

## 实体结构

```nix
den.hosts.x86_64-linux = {
  web-1 = { server-type = "cx22"; region = "fsn1"; users.deploy = { }; };
  web-2 = { server-type = "cx22"; region = "nbg1"; users.deploy = { }; };
};
```

| 主机 | 类型 | 区域 | 镜像 | 服务 |
|------|------|------|------|------|
| web-1 | cx22 | fsn1 (Falkenstein) | ubuntu-24.04 | nginx |
| web-2 | cx22 | nbg1 (Nuremberg) | ubuntu-24.04 | nginx |

Schema 扩展（`host-schema.nix`）：

```nix
{ config, lib, ... }: {
  options.server-type = lib.mkOption { type = lib.types.str; };
  options.region = lib.mkOption { type = lib.types.str; };
  options.image = lib.mkOption { type = lib.types.str; default = "ubuntu-24.04"; };
}
```

## 关键模式

### 1. 自定义 terranix 类

```nix
den.classes.terranix = { };
```

方面中的 `terranix` 键被管道收集到 `terranix` 类桶中。

### 2. 策略实例化

```nix
den.policies.host-to-terranix = { host, ... }: [
  (den.lib.policy.instantiate {
    name = "${host.name}-tf";
    class = "terranix";
    instantiate = { modules, ... }: modules;
    intoAttr = [ "terranixModules" host.name ];
  })
];
```

`den.lib.policy.instantiate` 在每主机作用域内解析所有 `terranix` 类贡献，收集模块列表存储到 `config.flake.terranixModules.<hostname>`。

### 3. 与 terranix flake-module 连接

```nix
imports = [ inputs.terranix.flakeModule ];

perSystem = { pkgs, system, ... }: {
  terranix.terranixConfigurations = lib.mapAttrs (_: modules: {
    inherit modules;
    terraformWrapper.package = pkgs.opentofu;
  }) (config.flake.terranixModules or { });
};
```

每主机的模块列表馈入 `terranix.terranixConfigurations`，自动生成 apply/plan/destroy 命令。

### 4. 静态 + 参数化方面

**静态 provider**（`provider.nix`）：

```nix
den.aspects.hcloud-provider = {
  terranix = {
    terraform.required_providers.hcloud = { ... };
    provider.hcloud.token = "...";
  };
};
```

**参数化 server**（`server.nix`）：

```nix
serverAspect = { host, ... }: {
  name = "hcloud-server/${host.name}";
  terranix = {
    resource.hcloud_server.${host.name} = {
      name = host.hostName;
      server_type = host.server-type;
      location = host.region;
      image = host.image;
    };
  };
};
```

参数化方面确保每主机产生唯一的资源键（`hcloud_server.web-1` vs `hcloud_server.web-2`）。

### 数据流

```
den.hosts.x86_64-linux.web-1
  │
  ├── host-schema: server-type, region, image
  │
  ├── nixos class  → NixOS 配置（web-1.nix 的 nginx）
  │
  └── terranix class → policy.host-to-terranix
        │
        ▼
  config.flake.terranixModules.web-1
        │
        ▼
  terranix.terranixConfigurations.web-1
        │
        ▼
  nix build .#web-1.config  →  config.tf.json
  nix run  .#web-1          →  tofu apply
```

## 与其他模板对比

| 特性 | terranix-demo | microvm |
|------|--------------|---------|
| 自定义类 | `terranix` | `microvm` |
| 策略 | `host-to-terranix`（instantiate） | 3 层策略链 |
| 输出 | Terraform JSON | QEMU VM |
| 外部工具 | terranix + OpenTofu | microvm.nix |
| 使用场景 | 基础设施即代码 | 虚拟化 |
