{ den, ... }:
{

  # Parametric aspect: (den.aspects.apps.terminals.tabby (p: [ p.hidapi p.maple-mono.NF-CN ]))
  den.aspects.apps.terminals.tabby = extraPkgs: {
    homeManager = { pkgs, ... }: {
      home.packages = [
        (pkgs.callPackage ../../../../packages/tabby-terminal.nix { inherit extraPkgs; })
      ];
    };
  };
}
