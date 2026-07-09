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
        config = {
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
                expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options";
              };
              home-manager = {
                expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options.home-manager.users.type.getSubOptions []";
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
