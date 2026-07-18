{ inputs, den, ... }:
{
  # DankCalendar (dcal) — danklinux 生态的桌面日历应用
  # 与 DMS 日历组件原生集成，systemd 随 niri 会话后台常驻
  den.aspects.desktop.shell.dms-shell.dankcalendar = {
    homeManager = {
      imports = [ inputs.dankcalendar.homeModules.dank-calendar ];
      programs.dank-calendar = {
        enable = true;
        systemd = {
          enable = true;
          # 与主 dms-shell 的 systemd.target 保持一致
          target = "niri.service";
        };
        # 写入 ~/.config/dankcal/ui-settings.json
        settings = {
          use24HourClock = true;
        };
      };
    };
  };
}
