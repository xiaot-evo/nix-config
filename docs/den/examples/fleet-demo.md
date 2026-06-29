# fleet-demo 模板

**Fleet 级多主机编排** — 展示 Den 的 Pipe（Quirk）系统用于跨主机数据共享，以及自定义实体类型（environment）和注册表驱动用户访问控制。

## 用途

- 管理多个环境（prod/staging）的多主机集群
- 跨主机共享数据（IP 地址、后端列表等）
- 注册表驱动的用户访问控制（组权限）
- 学习自定义实体类型和策略链

## 目录结构

```
templates/fleet-demo/
├── flake.nix              # 入口（flake-parts + import-tree）
├── flake.lock
├── README.md              # 完整文档（559 行）
├── diagrams/fleet/        # 预生成的 Mermaid 图
└── modules/
    ├── den.nix             # 主机定义 + 默认配置
    ├── environments.nix    # 自定义 entity: environment
    ├── users.nix           # 用户注册表 + 访问映射
    ├── diagrams.nix        # fleet 级图表生成
    ├── flake-parts.nix     # flake-parts 系统
    └── policies/
        ├── fleet.nix       # 作用域树策略链
        └── pipes.nix       # Pipe 声明 + 收集策略
        aspects/
          ├── features/
          │   ├── haproxy.nix      # 消费 http-backends pipe
          │   ├── nginx.nix        # 发出 http-backends pipe
          │   └── hostfile.nix     # 发出 & 消费 host-addrs pipe
          ├── hosts/
          │   ├── lb-prod.nix      # 生产负载均衡器
          │   ├── web-prod-1.nix   # 生产 Web 服务器 1
          │   ├── web-prod-2.nix   # 生产 Web 服务器 2
          │   └── web-staging.nix  # 暂存 Web 服务器
          └── users/
              └── ssh-keys.nix     # SSH 密钥电池
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `den` | path:../.. | Den 框架（本地） |
| `den-diagram` | github:denful/den-diagram | 渲染库 |
| `import-tree` | github:vic/import-tree | 递归导入 |
| `flake-parts` | github:hercules-ci/flake-parts | perSystem |
| `nixpkgs` | nixpkgs-unstable (tarball) | 包集合 |
| `home-manager` | github:nix-community/home-manager | 用户环境 |

## 实体结构

### 环境与主机

| 环境 | 主机 | 地址 | 角色 |
|------|------|------|------|
| prod | lb-prod | 10.0.1.1 | 负载均衡 |
| prod | web-prod-1 | 10.0.1.10 | Web 服务器 |
| prod | web-prod-2 | 10.0.1.11 | Web 服务器 |
| staging | web-staging | 10.0.2.10 | Web 服务器 |

### 用户注册表与访问控制

```nix
den.users.registry = {
  alice = { groups = [ "admin" ]; ... };
  bob   = { groups = [ "deploy" ]; ... };
};

fleet.user-access.by-environment = {
  prod    = { groups = [ "admin" ]; };
  staging = { groups = [ "admin" "deploy" ]; };
};
```

- alice（admin 组）→ prod + staging 均可访问
- bob（deploy 组）→ 仅 staging 可访问

## 关键模式

### 1. 自定义实体类型 Environment

```nix
# 注册为新实体
den.schema.environment.isEntity = true;

# 注册实例
fleet.environments = {
  prod    = { domain-name = "example.com"; };
  staging = { domain-name = "staging.example.com"; };
};

# 扩展主机 schema
den.schema.host.imports = [ { options = { ... }; } ];
```

### 2. 策略链

默认 Den 策略直接遍历 `den.hosts`。本模板用自定义策略链替代：

```
flake → fleet → environment → host → user
```

| 策略 | 触发层级 | 作用 |
|------|----------|------|
| `to-fleet` | flake | 创建 fleet entity |
| `fleet-to-envs` | fleet | 展开到每个 environment |
| `env-to-hosts` | environment | 过滤匹配环境的主机 |
| `env-users` / `host-users` | host | 按组过滤用户 |

### 3. Pipe 系统（Quirks）

Pipe 是 Den 的 quirk 系统，实现同一环境中兄弟主机的数据共享。

**声明 Pipe**：

```nix
den.quirks.http-backends = { description = "HTTP 后端地址"; };
den.quirks.host-addrs   = { description = "主机地址"; };
```

**发出数据（nginx）**：

```nix
# http-backends 键匹配 quirk 名，自动触发
den.aspects.web-1.http-backends = [ { addr = "10.0.1.10"; port = 80; } ];
```

**收集数据（haproxy）**：

```nix
den.policies.collect-backends = { host, ... }: [
  (pipe.from "http-backends" [
    (pipe.collect ({ host, ... }: true))  # 收集同环境所有
  ])
];
```

**消费数据（haproxy）**：

```nix
den.aspects.lb-prod = { http-backends, ... }: {
  # http-backends 作为参数自动注入
  ... 生成 HAProxy 配置
};
```

### 4. 禁用默认策略

```nix
den.schema.flake-system.excludes = [
  den.policies.system-to-os-outputs
  den.policies.system-to-hm-outputs
];
den.schema.host.excludes = [ den.policies.host-to-users ];
```

确保自定义策略链免受默认策略干扰。

### 5. 电池化 SSH 密钥

```nix
den.aspects.ssh-keys = {
  includes = [
    ({ host, user }: {
      name = "ssh-keys/${user.userName}@${host.name}";
      nixos.users.users.${user.userName}.openssh.authorizedKeys.keys = user.ssh-keys;
    })
  ];
};
```

参数化子方面确保每用户每主机具有独立身份 ID，防止管道去重。

## 其他模板对比

| 特性 | fleet-demo | diagram-demo |
|------|-----------|-------------|
| 核心关注 | **跨主机数据流** | 方面级可视化 |
| 自定义实体 | ✅ environment | ❌ |
| Pipe 系统 | ✅ 深度使用 | ❌ |
| 注册表用户 | ✅ | ❌ |
| 策略链 | ✅ 5 级 scope | ❌ |
| 主机数 | 4 | 3 |
