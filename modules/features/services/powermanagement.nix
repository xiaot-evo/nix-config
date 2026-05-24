{ den, ... }:
{
  den.aspects.services.powermanagement = {
    nixos = {
      services = {
        accounts-daemon.enable = true;
        # power-profiles-daemon.enable = true;
        tuned.enable = true;
        upower.enable = true;
      };
    };
  };
}
