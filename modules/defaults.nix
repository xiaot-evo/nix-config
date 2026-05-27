{ lib, den, ... }:
{
  den.default.nixos.system.stateVersion = "26.11";
  den.default.homeManager.home.stateVersion = "26.05";

  # Enable strict mode for all hosts
  den.schema.host.strict = true;

  # enable hm by default
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
}
