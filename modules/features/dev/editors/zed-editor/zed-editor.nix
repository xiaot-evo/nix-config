{ den, ... }:
{
  den.aspects.dev.editors.zed-editor = {
    homeManager =
      {
        self',
        pkgs,
        lib,
        ...
      }:
      {
        programs.zed-editor = {
          enable = true;
          package = pkgs.zed-editor;
          extraPackages = with pkgs; [
            nixd
            nixfmt
            package-version-server
            yaml-language-server
          ];
          extensions = [
            "html"
            "nix"
            "git-firefly"
            "toml"
            "catppuccin"
            "catppuccin-icons"
          ];
          userSettings =
            (import ./_settings.nix { inherit self' pkgs lib; }) // (import ./_languages.nix { inherit pkgs; });
          userKeymaps = import ./_keymap.nix;
        };
      };
  };
}
