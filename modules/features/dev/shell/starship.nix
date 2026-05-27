{ den, ... }:
{
  den.aspects.dev.shell.starship = {
    homeManager =
      { ... }:
      {
        programs.starship = {
          enable = true;
          enableFishIntegration = true;
          settings = builtins.fromTOML (
            builtins.readFile (
              builtins.fetchurl {
                url = "https://starship.rs/presets/toml/plain-text-symbols.toml";
                sha256 = "sha256-BPGFwSS0jw1DIK3u0PdHGt0RD82mWUs1LtRk65W/HtM=";
              }
            )
          );
        };
      };
  };
}
