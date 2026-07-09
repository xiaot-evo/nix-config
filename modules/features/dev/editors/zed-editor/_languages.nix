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
      settings = {
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
  };
}
