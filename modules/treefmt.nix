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

        # ── 排除外部文档（非本项目维护内容）────────
        settings.global.excludes = [
          "docs/den/**" # Den 框架文档（上游维护）
        ];
      };
    in
    {
      formatter = treefmtEval.config.build.wrapper;
      checks = {
        formatting = treefmtEval.config.build.check self;
      };
    };
}
