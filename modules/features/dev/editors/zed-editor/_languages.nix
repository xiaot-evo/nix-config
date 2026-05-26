{ pkgs, ... }:
{
  languages = {
    Nix = {
      language_servers = [
        "nixd"
        "!nil"
      ];
    };
  };
  lsp = {
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
            # "sema-extra-with"
          ];
        };
      };
    };
  };
}
