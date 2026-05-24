# 笔记本风扇控制 (NoteBook FanControl)
# 参数 ConfigId：nbfc.json 中的配置 ID（对应机型）
{ ... }:

{
  den.aspects.system.hardware.nbfc-linux = ConfigId: {
    nixos =
      { pkgs, ... }:
      let
        # 动态生成 nbfc.json，写入所选配置 ID
        nbfcConfig = pkgs.writeTextFile {
          name = "nbfc.json";
          text = ''
            {
              "SelectedConfigId": "${ConfigId}"
            }
          '';
        };
        command = "bin/nbfc_service --config-file ${nbfcConfig}";
      in
      {
        environment.systemPackages = with pkgs; [ nbfc-linux ];

        # nbfc_service systemd 服务
        systemd.services.nbfc_service = {
          enable = true;
          description = "NoteBook FanControl service";
          serviceConfig.Type = "simple";
          path = [ pkgs.kmod ];
          script = "${pkgs.nbfc-linux}/${command}";
          wantedBy = [ "multi-user.target" ];
        };
      };
  };
}
