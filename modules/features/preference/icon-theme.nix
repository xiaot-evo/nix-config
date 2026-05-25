{ den, ... }:
{
  den.aspects.preference.icon-theme = {
    homeManager =
      { pkgs, ... }:
      {
        gtk = {
          enable = true;
          iconTheme = {
            name = "WhiteSur-light";
            package = pkgs.whitesur-icon-theme;
          };
        };
      };
  };
}
