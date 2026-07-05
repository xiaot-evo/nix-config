# fx 模块

**源文件**: `nix/lib/fx.nix`

## 概述

代数效果（Algebraic Effects）库的薄重新导出层。`nix-effects` 提供了 Den 方面引擎 FX 管道的核心原语——`fx.send`、`fx.bind`、`fx.pure`、`fx.seq` 等。此模块优先尝试使用 `inputs.nix-effects`（如果 flake 使用者提供了该输入），否则从 `templates/ci/flake.lock` 中锁定的版本获取。

______________________________________________________________________

## 导出

`fx` 模块整体作为 `den.lib.fx` 导出，直接暴露 `nix-effects` 库的全部接口。

### 签名

```nix
fx :: {
  send    :: EffectName -> Param -> Effect,
  bind    :: Effect -> (Param -> Handler) -> Handler,
  pure    :: Value -> Handler,
  seq     :: [Handler] -> Handler,
  handle  :: { handlers :: AttrSet Handler, state :: State } -> Handler -> Result,
  ...
}
```

### 用途

提供代数效果编程模型，使 FX 管道能够以声明式方式处理状态变化。每个管道效果（resolve、compile、classify、emit-classes 等）都是通过 `fx.send` 分派的代数效果，由相应的处理程序处理。

### 回退机制

```
1. 检查 inputs.nix-effects 是否存在
   ├── 存在：直接使用 inputs.nix-effects.lib
   └── 不存在：
       ├── 读取 templates/ci/flake.lock
       ├── 从中提取 nix-effects 节点的锁定信息
       └── 使用 builtins.fetchTarball 获取锁定的源码
```

### 锁定文件结构

`templates/ci/flake.lock` 中的 `nodes.nix-effects` 包含：

```nix
{
  locked = {
    owner = "denful";
    repo = "nix-effects";
    rev = "<commit-hash>";
    narHash = "<sha256-hash>";
  };
}
```

### 使用示例

```nix
# 在管道处理程序中发送效果
{ den, fx, ... }:
let
  # 发送 resolve 效果
  resolveEffect = fx.send "resolve" {
    aspect = myAspect;
    identity = "my-identity";
    ctx = { host = { name = "igloo"; }; };
    gated = true;
  };
in
# 效果由 fx.handle 处理
fx.handle {
  handlers = {
    "resolve" = { param, state }: {
      resume = resolvedValue;
      state = state;
    };
  };
  state = { };
} resolveEffect
```

```nix
# 组合处理程序
fx.handle {
  handlers = fx.composeHandlers defaultHandlers extraHandlers;
  state = defaultState;
} pipelineProgram
```

### 实现简析

1. 尝试从 `inputs.nix-effects` 获取——这是最直接的方式，允许 flake 使用者覆盖版本
1. 如果不可用，从锁定文件（`templates/ci/flake.lock`）中读取 `nix-effects` 节点
1. 使用 `builtins.fetchTarball` 从 GitHub archive URL 获取，并验证 `narHash`
1. 导入获取到的源码，传入 `lib` 作为参数

这种双重机制确保了开发环境（有 flake 锁）和生产环境（可能无锁）都能正常工作。

______________________________________________________________________

## 关联函数

- `aspects/fx/pipeline.md` — 管道编排器，fx 核心原语的主要消费者
- `aspects/fx/resolve.md` — resolve 效果处理器，使用 fx.send 驱动方面解析
- `den.lib.aspects` — 顶层方面引擎，使用 fx 模块启动管道

## 关联文档

- [代数效果](../../11-%E9%AB%98%E7%BA%A7%E4%B8%BB%E9%A2%98.md) — 代数效果管道的概念和调试
- [nix-effects 库](https://github.com/denful/nix-effects) — 底层效果库的完整文档
