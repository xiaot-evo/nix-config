{ den, ... }:
{
  den.aspects.dev.tools.yazi = {
    homeManager = { pkgs, ... }: {
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        extraPackages = [ pkgs.trash-cli ];
        settings = {
          trash.bin = "trash";
          manager.sort_by = "natural";
          manager.sort_sensitive = false;
        };
      };
    };
  };
}
