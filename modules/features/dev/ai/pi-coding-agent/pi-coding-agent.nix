{ den, ... }: {
  den.aspects.dev.ai.pi-coding-agent = {
    includes = [
      den.batteries.inputs'
    ];
    homeManager = { pkgs, inputs', ... }: {
      # 使用 llm-agents.nix 提供的 pi 包
      programs.pi-coding-agent.package = inputs'.llm-agents-nix.packages.pi;

      imports = [
        ./_packages.nix
        ./_home-files.nix
      ];
    };
  };
}
