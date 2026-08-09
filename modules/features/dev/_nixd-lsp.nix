# 共享 nixd LSP 配置 — claude-code / helix / zed 三处复用，避免重复
# `_` 前缀文件不会被 import-tree 注册为 aspect，仅作显式 import 的 helper。
# 单主机配置，主机名硬编码于此；未来新增主机时改为参数化传入。
{
  hostName ? "acer-swift",
}:
{
  nixd = {
    nixpkgs = {
      expr = "import <nixpkgs> {}";
    };
    formatting = {
      command = [ "nixfmt" ];
    };
    diagnostic = {
      suppress = [ ];
    };
    options = {
      nixos = {
        expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${hostName}.options";
      };
      home-manager = {
        expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${hostName}.options.home-manager.users.type.getSubOptions []";
      };
    };
  };
}
