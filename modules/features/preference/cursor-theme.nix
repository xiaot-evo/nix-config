{ den, ... }:
{
  den.aspects.preference.cursor-theme = {
    homeManager =
      { pkgs, ... }:
      {
        home.pointerCursor = {
          enable = true;
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 24;
          x11 = {
            enable = true;
            defaultCursor = "Bibata-Modern-Classic";
          };
        };
      };
  };
}
