{ den, ... }: {
  den.aspects.dev.editors.pi-coding-agent = {
    homeManager = { ... }: {
      imports = [
        ./_packages.nix
        ./_home-files.nix
      ];
    };
  };
}
