{ den, ... }:
{
  den.aspects.dev.editors.opencode = {
    homeManager = { ... }: {
      programs.opencode = {
        enable = true;
        tui.theme = "opencode";
        settings = {
          plugin = [
            "opencode-antigravity-auth@latest"
            "@tarquinen/opencode-dcp@latest"
            "superpowers@git+https://github.com/obra/superpowers.git"
          ];
          mcp.nixos = {
            enabled = true;
            type = "local";
            command = [
              "nix"
              "run"
              "github:utensils/mcp-nixos"
              "--"
            ];
          };
        };
      };
    };
  };
}
