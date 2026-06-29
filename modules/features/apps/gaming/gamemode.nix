{ ... }: {
  den.aspects.apps.gaming.gamemode = {
    user = {
      extraGroups = [
        "gamemode"
      ];
    };
    nixos = {
      programs.gamemode = {
        enable = true;
        # settings = {};
      };
    };
  };
}
