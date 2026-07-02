{ den, ... }:
{
  den.aspects.dev.editors.helix = {
    homeManager =
      { pkgs, ... }:
      {
        imports = [
          ./_settings.nix
          ./_languages.nix
        ];
        programs.helix = {
          enable = true;
          # defaultEditor = true;
          extraPackages = with pkgs; [
            nil
            nixfmt
            # go
            gopls
            delve
          ];
        };
      };
  };
}
