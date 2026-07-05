{ self, inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";

        # ── Nix ─────────────────────────────────────
        programs.nixfmt.enable = true;

        # ── JSON ────────────────────────────────────
        programs.jsonfmt.enable = true;

        # ── Markdown ────────────────────────────────
        programs.mdformat.enable = true;

        # ── YAML ────────────────────────────────────
        programs.yamlfmt.enable = true;
      };
    in
    {
      formatter = treefmtEval.config.build.wrapper;
      checks = {
        formatting = treefmtEval.config.build.check self;
      };
    };
}
