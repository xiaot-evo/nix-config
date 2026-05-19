{ den, ... }:
{
  den.aspects.xiaot_evo = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      (den.batteries.user-shell "fish")
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ htop ];
      };

    provides.to-hosts.nixos = {
      users.users.xiaot_evo.extraGroups = [ "wheel" "networkmanager" ];
    };
  };
}
