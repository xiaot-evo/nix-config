# noflake 模板

**无 flake 使用 Den** — 使用 npins 锁依赖，无需 Nix flake 机制，适合稳定 Nix 版本或偏好 npins 的项目。

## 用途

- 使用 Nix 稳定版（无 flake 支持）的环境中运行 Den
- 偏好 npins 的团队（支持 channel/tarball/PyPI/Docker 等非 git 源）
- 需最简依赖场景（无 flake-parts，用 nix-maid/hjem 替代 home-manager）
- 从传统 NixOS 配置迁移到 Den 的渐进路径

## 目录结构

```
templates/noflake/
├── default.nix             # 入口（替代 flake.nix）
├── README.md
├── npins/
│   ├── sources.json        # 锁定依赖（npins 格式）
│   └── default.nix         # npins 库（勿编辑）
└── modules/
    ├── den.nix             # Den 配置（主机/用户/方面）
    └── nh.nix              # Shell 构建命令
```

**无** `flake.nix`、`flake.lock`。

## 依赖管理（npins）

### sources.json 示例

```json
{
  "nixpkgs": {
    "type": "Channel",
    "url": "https://releases.nixos.org/...",
    "revision": "566acc07c54d"
  },
  "den": {
    "type": "Git",
    "repository": {
      "url": "https://github.com/denful/den"
    },
    "revision": "fba67817bd16..."
  },
  "hjem": { "type": "Git", ... },
  "import-tree": { "type": "Git", ... },
  "nix-maid": { "type": "Git", ... },
  "with-inputs": { "type": "Git", ... }
}
```

### 常用命令

```bash
npins add github denful/den         # 新增依赖
npins update den                    # 更新某个依赖
npins update                        # 更新全部
NPINS_OVERRIDE_den=~/den nix-build . -A ...  # 本地覆盖
```

## 实体结构

```nix
den.hosts.x86_64-linux.igloo.users = {
  tux.classes = [ "maid" ];
  pingu.classes = [ "hjem" ];
};
```

- 主机 `igloo`，两个用户：`tux`（nix-maid）、`pingu`（hjem）
- 使用 **nix-maid** / **hjem** 替代 home-manager

## 关键模式

### default.nix 入口

```nix
let
  sources = import ./npins;
  with-inputs = import sources.with-inputs sources;
  outputs = inputs:
    (inputs.nixpkgs.lib.evalModules {
      modules = [ (inputs.import-tree ./modules) ];
      specialArgs = { inherit inputs; inherit (inputs) self; };
    }).config;
in
with-inputs outputs
```

`with-inputs` 将 npins 的惰性取指器转换为标准 flake 风格 `inputs` attrset，使模块代码无需区分来源。

### 构建命令

```bash
# 构建
nix-run . -A den.sh --run igloo
# 部署
nix-run . -A den.sh --run 'igloo switch'
# 或传统方式
nixos-rebuild build --file . -A flake.nixosConfigurations.igloo
```

## 关键模式

- **Angular brackets in modules**: `{ den, inputs, ... }` 直接在模块函数参数中使用——无需 specialArgs 手动传递
- **Multiple `.addScoped` calls compose together**: 每次调用都合并作用域，模块参数自动合并所有库
- **`__findFile` for `<entity>` syntax**: Den 的 `__findFile` 被作用域化后，`<igloo>` 语法在模块中直接可用（自动解析为 `den.hosts.x86_64-linux.igloo`）

## 与其他模板对比

| 特性 | noflake | minimal | scoped-import-tree |
|------|---------|---------|-------------------|
| 锁依赖机制 | npins | flake.lock | flake.lock |
| 用户系统 | nix-maid/hjem | 无 (user 类) | 无 (user 类) |
| 构建命令 | `nix-run -A den.sh` | `nix run .#igloo` | `nix run .#igloo` |
| CI 覆盖 | 手动设 outPath | `--override-input` | `--override-input` |
| 适用场景 | 稳定 Nix / 非 flake | 现代化 flake | 多库项目 |
