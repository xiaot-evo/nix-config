{ den, ... }:
{
  den.aspects.desktop.budgie = {
    nixos = {
      services.xserver.enable = true;
      services.desktopManager.budgie.enable = true;
    };
  };
}
