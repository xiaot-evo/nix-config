{ inputs, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
  ];

  # other inputs may be defined at a module using them.
  flake-file = {
    description = "XiaoT_Evo's Nix Configuration with Den";
    outputs = "inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree [ ./modules ])";
    nixConfig = {
      extra-substituters = [
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
        "https://cache.numtide.com"
        "https://niri-nix.cachix.org"
        "https://attic.xuyh0120.win/lantian"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];
    };
    inputs = {
      den.url = "github:denful/den";
      flake-file.url = "github:vic/flake-file";
      home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      # We recommend following our Hjem input
      # hjem.follows = "hjem-rum/hjem";

      # You can also manage your own Hjem version, but this may come with breakage (read the admonition above)
      hjem = {
        url = "github:feel-co/hjem";
        # You may want hjem to use your defined nixpkgs input to
        # minimize redundancies.
        inputs.nixpkgs.follows = "nixpkgs";
      };
      hjem-rum = {
        url = "github:snugnug/hjem-rum";
        # You may want hjem-rum to use your defined nixpkgs input to
        # minimize redundancies.
        inputs.nixpkgs.follows = "nixpkgs";
        # Same goes for hjem, to avoid discrepancies between the version
        # you use directly and the one hjem-rum uses.
        inputs.hjem.follows = "hjem";
      };
      nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
      # Do not override its nixpkgs input, otherwise there can be mismatch between patches and kernel version
      daeuniverse.url = "github:daeuniverse/flake.nix";
      niri-nix = {
        url = "git+https://codeberg.org/BANanaD3V/niri-nix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      dms = {
        url = "github:AvengeMedia/DankMaterialShell/stable";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      dms-plugin-registry = {
        url = "github:AvengeMedia/dms-plugin-registry";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      # danklinux 生态实用工具：索引文件搜索（集成 DMS 启动器）
      danksearch = {
        url = "github:AvengeMedia/danksearch";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      # AI coding agent packages（pi, claude-code 等）
      llm-agents-nix = {
        url = "github:numtide/llm-agents.nix";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      treefmt-nix = {
        url = "github:numtide/treefmt-nix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      zen-browser = {
        url = "github:0xc000022070/zen-browser-flake";
        inputs = {
          # IMPORTANT: To ensure compatibility with the latest Firefox version, use nixpkgs-unstable.
          nixpkgs.follows = "nixpkgs";
          home-manager.follows = "home-manager";
        };
      };
    };
  };
}
