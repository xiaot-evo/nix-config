{ pkgs, ... }:
{
  languages = {
    Nix = {
      language_servers = [
        "!nixd"
        "nil"
      ];
    };
  };
  lsp = {
    nil = {
      settings = {
        formatting = {
          # 外部格式化命令（含参数）。
          # 从 stdin 接收文件内容，输出格式化后的代码到 stdout。
          # 类型: [string] | null
          # 推荐: ["nixfmt"]
          command = [ "nixfmt" ];
        };
        diagnostics = {
          # 忽略的诊断类型。
          # 类型标识为 snake_case 字符串，通常与诊断消息一起显示。
          # 类型: [string]
          # 示例: ["unused_binding", "unused_with"]
          ignored = [ ];
          # 排除文件，不显示诊断信息。适用于生成的文件。
          # 接受路径数组，相对路径相对于工作区根目录。
          # 不支持 glob 模式。
          # 类型: [string]
          # 示例: ["Cargo.nix"]
          excludedFiles = [ ];
        };
        nix = {
          # `nix` 二进制文件路径。
          # 类型: string
          # 示例: "/run/current-system/sw/bin/nix"
          binary = "${pkgs.nix}/bin/nix";
          # `nix` 评估的堆内存限制（MiB）。
          # 目前仅适用于启用 autoEvalInputs 时的 flake 评估，且仅 Linux 有效。
          # null 表示无限制。
          # 参考: `nix flake show --legacy nixpkgs` 通常需要约 2GiB。
          #
          # 类型: number | null
          # 推荐: 1024（足够多数项目）
          maxMemoryMB = 4096;
          flake = {
            # 自动归档行为（可能使用网络）。
            #
            # - null: 每次都询问。
            # - true: 必要时自动运行 `nix flake archive`。
            # - false: 不归档，仅加载已在磁盘上的 inputs。
            # 类型: null | boolean
            # 推荐: false（避免意外网络请求）
            autoArchive = false;
            # 是否自动评估 flake inputs。
            # 评估结果用于改进补全，但可能消耗大量时间和/或内存。
            #
            # 类型: boolean
            # 推荐: false（保持轻量）
            autoEvalInputs = true;
            # nixpkgs 在 flake inputs 中的名称，用于 NixOS 选项评估。
            #
            # 选项层次结构用于改进补全，但可能消耗大量时间和/或内存。
            # 若为 null 或在工作区 flake inputs 中未找到，则不评估 NixOS 选项。
            #
            # 类型: null | string
            # 推荐: "nixpkgs"
            nixpkgsInputName = "nixpkgs";
          };
        };
      };
    };
    nixd = {
      settings = {
        nixpkgs = {
          # flake 方式导入 nixpkgs
          expr = "import (builtins.getFlake (builtins.toString ./.)).inputs.nixpkgs { }";
        };
        formatting = {
          # 格式化命令
          command = [ "nixfmt" ];
        };
        # 配置语言服务器的选项集，用于补全。延迟评估。
        options = {
          nixos = {
            expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options";
          };
          home-manager = {
            expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options.home-manager.users.type.getSubOptions []";
          };
          # Den 框架选项 (den.aspects, den.batteries, den.hosts 等)
          den = {
            expr = "(builtins.getFlake (builtins.toString ./.)).debug.options.den.type.getSubOptions []";
          };
          # flake-parts perSystem 选项
          flake-parts = {
            expr = "(builtins.getFlake (builtins.toString ./.)).currentSystem.options";
          };
        };
        # 诊断系统控制
        diagnostic = {
          suppress = [
            "sema-extra-with"
          ];
        };
      };
    };
  };
}
