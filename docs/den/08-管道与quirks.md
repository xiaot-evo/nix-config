# 管道与 Quirks

## Quirks（管道）是什么

**Quirk** 是方面在注册于 `den.quirks` 的命名键上发射的结构化数据。一个 **pipe**（管道）是路由、过滤、变换或聚合 quirk 数据的策略效果——在一个作用域内或跨主机。

简单来说：quirk 是数据，pipe 是数据处理规则。

## Quirks 解决什么问题

Quirks 解决一个根本问题：多个方面如何贡献结构化数据，而单个消费者聚合它们？

考虑防火墙端口：Nginx、PostgreSQL、Redis 都需要开放端口。没有 quirk 时，你需要紧耦合：

```nix
# 没有 quirk——紧耦合
den.aspects.nginx = {
  nixos.networking.firewall.allowedTCPPorts = [ 80 443 ];
};
den.aspects.postgres = {
  nixos.networking.firewall.allowedTCPPorts = [ 5432 ];
};
```

有了 quirk，生产者不知道也不关心消费者：

```nix
# 有 quirk——解耦
den.aspects.nginx = {
  firewall = { ports = [ 80 443 ]; };
};
den.aspects.postgres = {
  firewall = { ports = [ 5432 ]; };
};
```

### 三个角色

| 角色 | 谁 | 做什么 |
|---|---|---|
| **生产者（Producer）** | 任何方面 | 在命名的 quirk 键上发射数据 |
| **架构师（Architect）** | 策略作者 | 通过 `pipe.from` 声明管道和路由 |
| **消费者（Consumer）** | 类模块 | 通过函数参数接收组装后的数据 |

生产者和消费者互不知晓。架构师通过策略 pipe 效果将它们连接起来。

## Quirk 声明

注册 quirk 名称，告诉管道将匹配的方面键分类为管道数据：

```nix
den.quirks.firewall = {
  description = "防火墙端口声明";
};
```

Quirk 名称不能与类名称（`den.classes`）冲突——管道在求值时断言这一点。

### 产生数据

任何方面都可以在 quirk 键上发射数据：

```nix
den.aspects.nginx = {
  nixos.services.nginx.enable = true;
  firewall = { ports = [ 80 443 ]; };
};

den.aspects.postgres = {
  nixos.services.postgresql.enable = true;
  firewall = { ports = [ 5432 ]; };
};
```

Quirk 值可以是 attrset、列表或任何 Nix 值。列表值会自动展平——`[ [a b] [c] ]` 变成 `[a b c]`。

### 消费数据

类模块通过命名 quirk 作为函数参数来接收数据：

```nix
den.aspects.networking = {
  nixos = { firewall, lib, ... }: {
    networking.firewall.allowedTCPPorts =
      lib.concatMap (f: f.ports or []) firewall;
  };
};
```

`firewall` 参数接收在当前作用域中收集的所有 quirk 值的列表。如果没有生产者发射数据，它是 `[]`。

### 管道时间鉴别器

当一个方面需要 quirk 参数（`{ firewall, ... }:`）时，管道在树遍历期间延迟它的包含。在所有生产者发射了数据并且管道组装完成后，延迟的方面才用组装的管道数据解析。

**包含顺序无关紧要。** 无论消费者出现在生产者之前还是之后，结果都是相同的。

## 管道阶段

所有管道阶段通过 `den.lib.policy.pipe` 访问：

```nix
let inherit (den.lib.policy) pipe; in
```

### `filter`——过滤

移除不匹配谓词的条目：

```nix
den.policies.tcp-only = { host, ... }:
  let inherit (den.lib.policy) pipe; in
  [ (pipe.from "firewall" [
      (pipe.filter (e: e.proto == "tcp"))
    ])
  ];
```

### `transform`——变换

将每个条目映射为新形状：

```nix
pipe.from "items" [
  (pipe.transform (i: { label = "x-${i.name}"; }))
]
```

### `fold`——折叠

将所有条目归约为单个值：

```nix
pipe.from "nums" [
  (pipe.fold (acc: n: acc + n) 0)
]
```

消费者收到单元素列表：输入 `[ 10 20 30 ]` 时得到 `[ 60 ]`。

### `append`——追加

向池中添加合成条目：

```nix
pipe.from "items" [
  (pipe.append { name = "default"; })
]
```

### `for`——遍历替换

替换整个列表。每个管道的每个作用域最多一个 `pipe.for`：

```nix
pipe.from "items" [
  (pipe.for (vals: lib.reverseList vals))
]
```

### `collect`——收集

从兄弟作用域收集数据。这是跨主机聚合的方式：

```nix
pipe.from "http-backends" [
  (pipe.collect ({ host, ... }: true))
]
```

谓词接收每个兄弟作用域的上下文 attrset。只有匹配实体类型的兄弟作用域才被考虑。

### `expose`——暴露

将子作用域的数据推送到父作用域：

```nix
pipe.from "prefs" [ pipe.expose ]
```

暴露的数据与父作用域本地数据合并。如果父方面也发射了同名的 quirk，消费者看到两者。

### `to`——定向交付

将管道数据路由到特定的方面：

```nix
pipe.from "firewall" [
  (pipe.to [ den.aspects.networking ])
]
```

只有命名的方面接收数据。同一管道的其他消费者看到未修改的池。

### 链式组合

阶段从左到右组合：

```nix
pipe.from "items" [
  (pipe.filter (i: i.keep))
  (pipe.transform (i: { label = "x-${i.name}"; }))
  pipe.expose
]
```

## 管道路由

### `pipe.to`——定向发送

```nix
den.policies.postgres-secrets = { host, ... }:
  let inherit (den.lib.policy) pipe; in
  [ (pipe.from "secrets" [
      (pipe.filter (_: false))           # 丢弃原有池
      (pipe.append { db-password = "/run/secrets/pg-pass"; })
      (pipe.for lib.mergeAttrsList)      # 合并为单个 attrset
      (pipe.to [ den.aspects.postgres ])
    ])
  ];
```

### `pipe.as`——创建派生 quirk

重命名管道输出，在不同名称下交付数据：

```nix
den.quirks.backends = { description = "后端地址"; };
den.quirks.monitoring-targets = { description = "监控目标"; };

den.policies.backends-to-monitoring = { host, ... }:
  let inherit (den.lib.policy) pipe; in
  [ (pipe.from "backends" [
      (pipe.transform (b: "${b.addr}:${toString b.port}"))
      (pipe.as "monitoring-targets")
    ])
  ];
```

`pipe.as` 必须指向与源不同的 quirk。自指向会抛出错误。

### 配置相关惰性求值（Config Thunk）

Quirk 值可以依赖主机的 NixOS `config`（没有 `pipe.thunk` 函数——thunk 是函数值 quirk 的隐式特性）：

```nix
den.aspects.my-service = {
  nixos.services.my-service.enable = true;
  firewall = { config, ... }: {
    ports = [ config.services.my-service.port ];
  };
};
```

- **本地 thunk**：在 `evalModules` 内部使用实体自身的 config 不动点惰性解析
- **跨主机 thunk**（通过 `pipe.collect`）：针对源主机的实例化配置急切解析

### `pipe.withProvenance`——跟踪来源

在收集的数据上附加来源信息：

```nix
pipe.from "http-backends" [
  (pipe.collect ({ host, ... }: true))
  pipe.withProvenance
]
```

消费者收到 `{ value; source; }` 记录，其中 `source` 是源作用域的完整上下文 attrset。

## 生产者与消费者模式

Quirk 系统是典型的生产者-消费者模式：

```
生产者 1 ──→  quirk 数据池  ──→ pipe.filter
生产者 2 ──→                ──→ pipe.transform  ──→ 消费者
生产者 3 ──→                ──→ pipe.fold
                              ──→ pipe.expose (上浮到父作用域)
                              ──→ pipe.collect (来自兄弟作用域)
```

生产者通过 `includes` 把数据放入池中。消费者在函数参数中声明依赖。策略在中间插入处理阶段。

## 跨作用域 collect（fleet 模式）

在 fleet（多主机）模式下，`pipe.collect` 收集兄弟主机作用域的数据：

```nix
den.hosts.x86_64-linux.igloo.users.tux = {};
den.hosts.x86_64-linux.iceberg.users.alice = {};

den.aspects.igloo = {
  http-backends = { addr = "10.0.0.1"; port = 8080; };
};
den.aspects.iceberg = {
  http-backends = { addr = "10.0.0.2"; port = 80; };
};

den.policies.fleet-backends = { host, ... }:
  let inherit (den.lib.policy) pipe; in
  [ (pipe.from "http-backends" [
      (pipe.collect ({ host, ... }: true))
    ])
  ];

den.schema.host.includes = [ den.policies.fleet-backends ];
```

`igloo` 主机看到的 `http-backends` 包含自身和 `iceberg` 的条目。

## 完整示例：从简单到复杂

### 简单：防火墙端口

```nix
# 最简单的 quirk 用法——同一作用域聚合

den.quirks.firewall = { description = "防火墙端口"; };

den.aspects.nginx = {
  firewall = { ports = [ 80 443 ]; };
};
den.aspects.postgres = {
  firewall = { ports = [ 5432 ]; };
};

den.aspects.networking = {
  nixos = { firewall, lib, ... }: {
    networking.firewall.allowedTCPPorts =
      lib.concatMap (f: f.ports or []) firewall;
  };
};

den.aspects.igloo = {
  includes = [
    den.aspects.nginx
    den.aspects.postgres
    den.aspects.networking
  ];
};
```

结果：`networking.firewall.allowedTCPPorts = [ 80 443 5432 ]`。

### 中级：跨主机收集 + 变换

```nix
den.quirks.http-addrs = { description = "HTTP 地址"; };

den.aspects.server-a = {
  http-addrs = { addr = "10.0.0.1"; port = 8080; };
};
den.aspects.server-b = {
  http-addrs = { addr = "10.0.0.2"; port = 80; };
};

den.policies.collect-as-urls = { host, ... }:
  let inherit (den.lib.policy) pipe; in
  [ (pipe.from "http-addrs" [
      (pipe.collect ({ host, ... }: true))
      (pipe.transform (a: "http://${a.addr}:${toString a.port}"))
      (pipe.as "peer-urls")
    ])
  ];

den.schema.host.includes = [ den.policies.collect-as-urls ];

den.aspects.monitor = {
  nixos = { peer-urls, lib, ... }: {
    services.prometheus.scrape_configs =
      map (url: { job_name = "peer"; static_configs = [{ targets = [ url ]; }]; }) peer-urls;
  };
};
```

### 高级：带来源追踪和数据过滤的完整 fleet 模式

```nix
den.quirks.metrics = { description = "指标端点"; };

den.aspects.web = {
  metrics = { host = "web-01"; port = 9090; };
};
den.aspects.db = {
  metrics = { host = "db-01"; port = 9187; };
};

den.policies.fleet-metrics = { host, ... }:
  let inherit (den.lib.policy) pipe; in
  [ (pipe.from "metrics" [
      (pipe.collect ({ host, ... }: true))
      (pipe.filter (m: m.port != 0))
      pipe.withProvenance
      (pipe.to [ den.aspects.prometheus ])
    ])
  ];

den.schema.fleet.includes = [ den.policies.fleet-metrics ];

den.aspects.prometheus = {
  nixos = { metrics, lib, ... }: {
    services.prometheus.scrape_configs = map (entry: {
      job_name = "fleet-${entry.source.host.name}";
      static_configs = [{
        targets = [ "${entry.value.host}:${toString entry.value.port}" ];
      }];
    }) metrics;
  };
};
```

## 与 Policies 的协作

Quirks 和 policies 的关系：

- **Policies** 决定拓扑——实体如何连接
- **Pipes** 是 policy effects 的一种——在拓扑之上路由数据
- **Quirks** 是数据合约——生产者和消费者之间协议

没有 policies 就没有 pipes——pipe 效果必须由 policy 产生。没有 quirks 就没有 pipe 数据——quirk 声明告诉管道哪些方面键是数据而非类模块。

## 参见

- [策略系统](./07-%E7%AD%96%E7%95%A5%E7%B3%BB%E7%BB%9F.md)——策略和 pipe 效果
- [高级主题](./11-%E9%AB%98%E7%BA%A7%E4%B8%BB%E9%A2%98.md)——fleet 管理、作用域划分

## 关联函数

| 函数 | 说明 |
|------|------|
| [`den.lib.policy`](functions/lib/policy-effects.md) | 策略效果构造器（pipe 效果） |
| [`den.lib.aspects.fx.assemble-pipes`](functions/lib/aspects/fx/assemble-pipes.md) | 管道数据组装 |
| [`den.lib.aspects.fx.key-classification`](functions/lib/aspects/fx/key-classification.md) | 键分类系统（pipeKeys） |
| [`den.lib.aspects.fx.pipeline`](functions/lib/aspects/fx/pipeline.md) | FX 管道编排器 |
