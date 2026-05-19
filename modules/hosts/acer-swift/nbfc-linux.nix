{ ... }:

{
  den.aspects.acer-nbfc = {
    nixos = { pkgs, ... }:
    let
      nbfcConfig = pkgs.writeTextFile {
        name = "nbfc.json";
        text = ''
          {
            "SelectedConfigId": "Acer Swift SFX14-41G"
          }
        '';
      };
      command = "bin/nbfc_service --config-file ${nbfcConfig}";
    in
    {
      environment.systemPackages = with pkgs; [ nbfc-linux ];

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
