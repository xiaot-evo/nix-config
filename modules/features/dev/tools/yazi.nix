{ den, ... }:
{
  den.aspects.dev.tools.yazi = {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.trash-cli ];
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        settings = {
          trash.bin = "trash";
          manager.sort_by = "natural";
          manager.sort_sensitive = false;
        };
      };
    };
  };
}
