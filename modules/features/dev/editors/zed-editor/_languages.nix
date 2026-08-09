{ pkgs, ... }:
{
  languages = {
    Nix = {
      language_servers = [
        "nixd"
      ];
    };
  };
  lsp = {
    nixd = {
      # 共享 nixd 配置（hostname 等集中在 dev/_nixd-lsp.nix）
      settings = import ../../_nixd-lsp.nix { };
    };
  };
}
