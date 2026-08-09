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
          '';
        };
      };
  };
}
