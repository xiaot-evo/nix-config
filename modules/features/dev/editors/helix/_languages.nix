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
        auto-format = true;
        language-servers = [ "gopls" ];
      }
    ];
    language-server = {
      nixd = {
        command = "${pkgs.nixd}/bin/nixd";
        # 共享 nixd 配置（hostname 等集中在 dev/_nixd-lsp.nix）
        config = import ../../_nixd-lsp.nix { };
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
