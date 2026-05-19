{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      packages.myopencode =
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        inputs.wrappers.wrappers.opencode.wrap {
          pkgs = pkgs;
          settings = {
            theme = "opencode";
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
}
