{ pkgs, ... }:
{
  languages = {
    Nix = {
      language_servers = [
        "nil"
      ];
    };
  };
  lsp = {
    nil = {
      settings = {
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
}
