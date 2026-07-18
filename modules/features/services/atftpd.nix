{
  den.aspects.services.atftpd.nixos = {
    services.atftpd = {
      enable = true;
      # TFTP 文件存储目录
      root = "/srv/tftp";
      # 额外命令行参数，例如:
      # extraOptions = [ "--bind-address 192.168.1.1" "--verbose=7" ];
      extraOptions = [ ];
    };
  };
}
