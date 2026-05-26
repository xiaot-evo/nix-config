{ den, ... }:
{
  den.aspects.apps.terminals.ghostty = {
    homeManager =
      { pkgs, ... }:
      {
        programs.ghostty = {
          enable = true;
          settings = {
            command = "${pkgs.fish}/bin/fish";
            # command = "${pkgs.nushell}/bin/nu";
            # theme
            theme = "dankcolors";
            # 窗口装饰
            window-decoration = "none";
            # 背景不透明度
            # background-opacity = 0.95;
            # 窗口高度
            # window-height = 44;
            # 窗口宽度
            # window-width = 126;
          };
        };
      };
  };
}
