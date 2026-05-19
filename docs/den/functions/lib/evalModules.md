# den.lib.evalModules

**源文件**: `nix/lib/evalModules.nix`

## 用途

Den 框架的主模块求值入口函数。类似于 NixOS 的 `lib.nixosSystem`，但扩展为支持 Den 的完整管道：实体声明、方面解析、策略分派、以及多类输出（NixOS、Darwin、Home Manager 等）。

## 签名

```nix
den.lib.evalModules : {
  modules :: [Module]
} -> {
  config :: {
    flake :: {
      nixosConfigurations :: AttrSet NixOSConfig,
      darwinConfigurations :: AttrSet DarwinConfig,
      homeConfigurations :: AttrSet HomeConfig,
      ...
    }
  }
}
```

## 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `modules` | [Module] | NixOS 模块列表，其中至少一个模块必须导入 `den.module` 并声明实体（`den.hosts`、`den.homes` 等）和方面（`den.aspects`） |

## 返回值

返回一个 NixOS `evalModules` 结果，其 `.config.flake` 下包含所有实体的最终配置输出：
- `nixosConfigurations` — NixOS 主机配置
- `darwinConfigurations` — Darwin 主机配置
- `homeConfigurations` — 独立 Home Manager 配置
- 其他自定义类输出

## 使用示例

### 基本用法（Flakes 方式）

```nix
{
  outputs = { self, nixpkgs, den, home-manager, ... }: {
    nixosConfigurations = (den.lib.evalModules {
      modules = [
        den.module

        # 声明主机和用户
        {
          den.hosts.x86_64-linux.igloo.users.tux = {};

          den.aspects.igloo = {
            includes = [ den.batteries.hostname ];
            nixos = { pkgs, ... }: {
              environment.systemPackages = [ pkgs.hello ];
            };
          };

          den.aspects.tux = {
            includes = [
              den.batteries.define-user
              den.batteries.primary-user
            ];
            homeManager = { pkgs, ... }: {
              home.packages = [ pkgs.vim ];
              home.stateVersion = "25.05";
            };
          };

          den.default.homeManager.home.stateVersion = "25.05";
        }

        # 启用 Home Manager
        ({ config, ... }: {
          den.schema.user.classes = [ "homeManager" ];
        })
      ];
    }).config.flake.nixosConfigurations;
  };
}
```

### 不使用 Flakes

```nix
let
  sources = import ./npins;
  den = import sources.den {};
in
(den.lib.evalModules {
  modules = [
    den.module
    ({ ... }: {
      imports = [ (import sources.home-manager).nixosModules.home-manager ];
      den.hosts.x86_64-linux.igloo.users.tux = {};
      # ... 其余配置
    })
  ];
}).config.flake.nixosConfigurations
```

## 实现简析

`den.lib.evalModules` 是 Den 管道的主入口，其内部流程：

1. **启动 NixOS `evalModules`**：以 `den.module` 为核心，加载所有用户模块
2. **实体收集**：处理 `den.hosts`、`den.homes` 等声明，为每个实体创建根方面
3. **方面解析**：对每个实体，调用 `den.lib.aspects.resolve` 解析其方面树
4. **策略分派**：执行注册的策略，处理实体间的关系（host→user、user→home 等）
5. **类模块收集**：将解析结果按类（nixos、darwin、homeManager 等）分拣
6. **最终求值**：对每个实体的每个类运行 NixOS `evalModules`，产生最终配置
7. **输出组装**：将结果组装到 `.config.flake.<outputType>` 下

与 `lib.nixosSystem` 的关键区别：
- **多类支持**：一次求值产生 NixOS + Darwin + Home Manager 配置
- **方面管道**：内置方面解析引擎，支持参数化、条件、转发方面
- **策略驱动**：实体关系由策略声明而非硬编码
- **自由格式实体**：实体属性可通过 `freeformType` 自由扩展

## 关联函数

- `den.lib.aspects.resolve` — 方面解析引擎，被 evalModules 内部调用
- `den.lib.aspects.resolveImports` — 仅解析 includes 链（嵌套解析场景）
- `den.lib.resolveEntity` — 为实体创建根方面
- `den.lib.home-env.makeHomeEnv` — 家庭环境集成，被 evalModules 用于 homeManager/hjem/maid
- `den.lib.nh` — nh 构建/部署工具，配合 evalModules 输出使用

## 关联文档

- [快速开始](../../01-快速开始.md) — 使用 `den.lib.evalModules` 的最小配置示例（方式 A：Flakes、方式 B：npins）
- [核心概念](../../02-核心概念.md) — 理解 evalModules 内部涉及的实体、方面、策略概念
