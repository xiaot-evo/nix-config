# Nix 守护进程配置
{ den, ... }: {
  den.aspects.system.nix = {
    nixos = { pkgs, ... }: {
      nix = {
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        package = pkgs.lixPackageSets.stable.lix;
      };
      nixpkgs.overlays = [
        (final: prev: {
          inherit (prev.lixPackageSets.stable)
            nixpkgs-review
            nix-eval-jobs
            nix-fast-build
            colmena
            ;
        })
      ];
      documentation.enable = false;
      # 或更细粒度
      documentation.man.enable = false;
      documentation.info.enable = false;
      documentation.doc.enable = false;
    };
  };
}
