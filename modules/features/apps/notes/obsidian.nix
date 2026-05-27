{ den, ... }:
{
  den.aspects.apps.notes.obsidian =
    { user, ... }:
    {
      includes = [
        (den.batteries.unfree [ "obsidian" ])
      ];
      homeManager = {
        programs.obsidian = {
          enable = true;
          cli.enable = true;
          defaultSettings = {
          };
          vaults.notes = {
            target = "/home/${user.userName}/Documents/notes";
          };
        };
      };
    };
}
