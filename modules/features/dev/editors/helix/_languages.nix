{ pkgs, ... }:
{
  programs.helix.languages = {
    language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        language-servers = [ "nixd" ];
      }
      {
        name = "go";
        # scope = "source.go";
        # injection-regex = "gp";
        # file-types = [ "go" ];
        # roots = [ "go.mod" ];
        auto-format = true;
        # formatter = {
        #   command = "${pkgs.go}/bin/gofmt";
        # };
        # comment-tokens = "//";
        language-servers = [ "gopls" ];
      }
    ];
    language-server = {
      nixd = {
        command = "${pkgs.nixd}/bin/nixd";
        # command = "nixd";
        config.nixd = {
          nixpkgs = {
            # 用于 flake。
            expr = "import (builtins.getFlake (builtins.toString ./.)).inputs.nixpkgs { }";
            # 这个表达式将被解释为 "nixpkgs" 的顶层
            # Nixd 会从中提供包、库的补全/信息。
            #
            # 资源使用：条目是延迟求值的，整个 nixpkgs 仅“名称”就会占用 200~300MB。
            #                包的文档、版本等信息会按需求值。
            # expr = "import <nixpkgs> { }";
          };
          # formatting = {
          #   # 你希望使用哪个命令进行格式化
          #   command = [ "nixfmt" ];
          # };
          # 告诉语言服务器你期望的选项集，用于补全
          # 这是延迟求值的。
          options = {
            # 求值信息的映射
            # 默认情况下，此条目将从 `import <nixpkgs> { }` 中读取
            # 你可以在这里编写任意的 Nix 表达式，以产生有效的 "options" 声明结果。
            #
            # *注意*：请将下面的 "<name>" 替换为你实际的配置名称。
            # 如果你不确定该使用什么，可以通过 `nix repl` 直接求值
            # 该表达式来进行验证。
            #
            nixos = {
              expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options";
            };
            home-manager = {
              expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options.home-manager.users.type.getSubOptions []";
            };
            den = {
              expr = "(builtins.getFlake (builtins.toString ./.)).debug.options.den.type.getSubOptions []";
            };
            flake-parts = {
              expr = "(builtins.getFlake \"./.\").currentSystem.options";
            };
          };
          # 控制诊断系统
          diagnostic = {
            suppress = [
              "sema-extra-with"
            ];
          };
        };
      };
      gopls = {
        command = "${pkgs.gopls}/bin/gopls";
        config.gofumpt = true;
      };
    };
    debugger = [
      {
        name = "go";
        transport = "tcp";
        command = "${pkgs.delve}/bin/dlv";
      }
    ];
  };
}
