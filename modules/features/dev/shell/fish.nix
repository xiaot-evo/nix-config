{ den, ... }:
{
  den.aspects.dev.shell.fish = {
    homeManager =
      { pkgs, ... }:
      {
        programs.fish = {
          enable = true;
          interactiveShellInit = ''
            set fish_greeting # Disable greeting
            ${pkgs.starship}/bin/starship init fish | source
            ${pkgs.devenv}/bin/devenv hook fish | source
          '';
        };
      };
  };
}
