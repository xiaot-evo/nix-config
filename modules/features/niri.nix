{ den, ... }:
{
  den.aspects.niri-nix =
    { inputs, ... }:
    {
      homeManager = {
        imports = [ inputs.niri-nix.homeModules.default ];
        wayland.windowManager.niri = {
          enable = true;
          settings = { };
        };
      };
    };
}
