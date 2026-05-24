{ den, ... }:
{
  den.aspects.services.ly = {
    nixos = {
      services.displayManager.ly = {
        enable = true;
        x11Support = true;
        settings = {

        };
      };
    };
  };
}
