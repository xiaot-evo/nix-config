# Nix 守护进程配置
{ den, ... }: {
  den.aspects.system.nix = {
    nixos = { ... }: {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
