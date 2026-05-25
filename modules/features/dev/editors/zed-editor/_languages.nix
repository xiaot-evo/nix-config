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
          # For flake.
          expr = "import (builtins.getFlake (builtins.toString \"./.\")).inputs.nixpkgs { }   ";

          # This expression will be interpreted as "nixpkgs" toplevel
          # Nixd provides package, lib completion/information from it.
          ##
          # Resource Usage = Entries are lazily evaluated, entire nixpkgs takes 200~300MB for just "names".
          ##                Package documentation, versions, are evaluated by-need.
          # expr = "import <nixpkgs> { }";
        };
        formatting = {
          # Which command you would like to do formatting
          command = [ "nixfmt" ];
        };
        # Tell the language server your desired option set, for completion
        # This is lazily evaluated.
        options = {
          # Map of eval information
          # By default, this entriy will be read from `import <nixpkgs> { }`
          # You can write arbitary nix expression here, to produce valid "options" declaration result.
          #
          # *NOTE* = Replace "<name>" below with your actual configuration name.
          # If you're unsure what to use, you can verify with `nix repl` by evaluating
          # the expression directly.
          #
          nixos = {
            expr = "(builtins.getFlake (builtins.toString \"./.\")).nixosConfigurations.acer-swift.options";
          };

          home-manager = {
            expr = "(builtins.getFlake (builtins.toString \"./.\")).nixosConfigurations.acer-swift.options.home-manager.users.type.getSubOptions []";
          };
          # Den framework options (den.aspects, den.batteries, den.hosts, etc.)
          den = {
            expr = "(builtins.getFlake (builtins.toString \"./.\")).debug.options.den.type.getSubOptions []";
          };
          # For a `perSystem` flake-parts option
          flake-parts = {
            expr = "(builtins.getFlake \"./.\").currentSystem.options";
          };
        };
        # Control the diagnostic system
        diagnostic = {
          suppress = [
            "sema-extra-with"
          ];
        };
      };
    };
  };
}
