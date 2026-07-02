{ pkgs, ... }:
{
  programs.helix.languages = {
    language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        language-servers = [ "nil" ];
      }
      {
        name = "go";
        auto-format = true;
        language-servers = [ "gopls" ];
      }
    ];
    language-server = {
      nil = {
        command = "${pkgs.nil}/bin/nil";
        config = {
          nil = {
            formatting = {
              command = [ "nixfmt" ];
            };
            diagnostics = {
              ignored = [ "unused_binding" ];
            };
            nix = {
              flake = {
                autoEvalInputs = true;
                nixpkgsInputName = "nixpkgs";
              };
            };
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
