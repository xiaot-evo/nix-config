{ inputs, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.fish = inputs.wrappers.wrappers.fish.wrap {
        inherit pkgs;
        configFile.content = "
          set fish_greeting # Disable greeting
          ${self'.packages.starship}/bin/starship init fish | source
          devenv hook fish | source
        ";
      };
    };
}
