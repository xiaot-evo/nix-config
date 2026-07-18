{ ... }: {
  den.aspects.system.network.nixos = {
    # 网络管理
    networking.networkmanager.enable = true;

    # 蓝牙
    hardware.bluetooth.enable = true;

    # 防火墙
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        25565
      ];
      allowedUDPPorts = [ 69 ];
      allowedUDPPortRanges = [
        {
          from = 4000;
          to = 4007;
        }
        {
          from = 8000;
          to = 8010;
        }
      ];
    };
  };
}
