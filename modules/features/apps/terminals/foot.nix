{ den, ... }: {
  den.aspects.apps.terminals.foot = {
    homeManager = { config, ... }: {
      programs.foot = {
        enable = true;
        server = {
          enable = true;
          systemdTarget = config.wayland.systemd.target;
        };
      };
    };
  };
}
