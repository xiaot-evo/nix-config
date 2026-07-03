{ inputs, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
  ];

  # other inputs may be defined at a module using them.
  flake-file = {
    description = "XiaoT_Evo's Nix Configuration with Den";
    nixConfig = {
      extra-substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
        "https://niri-nix.cachix.org"
        "https://cache.garnix.io"
        "https://cache.nixos-cuda.org"
        "https://attic.xuyh0120.win/lantian"
        "https://noctalia.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
    inputs = {
      den.url = "github:denful/den";
      flake-file.url = "github:vic/flake-file";
      home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      # wrappers = {
      #   url = "github:BirdeeHub/nix-wrapper-modules";
      #   inputs.nixpkgs.follows = "nixpkgs";
      # };
      nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
      # Do not override its nixpkgs input, otherwise there can be mismatch between patches and kernel version
      daeuniverse.url = "github:daeuniverse/flake.nix";
      niri-nix = {
        url = "git+https://codeberg.org/BANanaD3V/niri-nix";
      };
      dms = {
        url = "github:AvengeMedia/DankMaterialShell/stable";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      dms-plugin-registry = {
        url = "github:AvengeMedia/dms-plugin-registry";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      # AI coding agent packages（pi, claude-code, opencode, crush 等）
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

      # Noctalia — Rust 编写的平铺桌面环境/Shell
      # https://docs.noctalia.dev/
      noctalia = {
        url = "github:noctalia-dev/noctalia/cachix";
        # 不 follow nixpkgs 以确保二进制缓存命中
      };
    };
  };
}
