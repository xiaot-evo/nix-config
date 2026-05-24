{ den, ... }:
{
  den.aspects.system.fonts = {
    includes = [ (den.batteries.unfree [ "corefonts" ]) ];
    nixos =
      { pkgs, ... }:
      {
        fonts = {
          packages = with pkgs; [
            corefonts
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
            noto-fonts-color-emoji
            lxgw-wenkai
            wqy_zenhei # 文泉驿正黑体（补全 fallback）
            wqy_microhei # 文泉驿微米黑
            source-han-sans
            source-han-serif
            nerd-fonts.jetbrains-mono
            jetbrains-mono
            maple-mono.NF-CN
          ];
          fontDir.enable = true;
        };
      };
  };
}
