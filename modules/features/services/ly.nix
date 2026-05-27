{ den, ... }:
{
  den.aspects.services.ly = {
    includes = [
      den.aspects.security.gnome-keyring
    ];
    nixos =
      { pkgs, ... }:
      {
        services.displayManager.ly = {
          enable = true;
          x11Support = false;
          settings = {
            # Ly 支持 24 位真彩色样式，这意味着每种颜色都是一个 32 位值。
            # 格式为 0xSSRRGGBB，其中 SS 是样式，RR 是红色，GG 是绿色，BB 是蓝色。
            # 以下是可用的样式选项：
            # TB_BOLD      0x01000000
            # TB_UNDERLINE 0x02000000
            # TB_REVERSE   0x04000000
            # TB_ITALIC    0x08000000
            # TB_BLINK     0x10000000
            # TB_HI_BLACK  0x20000000
            # TB_BRIGHT    0x40000000
            # TB_DIM       0x80000000
            # 在编程中，你需要使用按位或运算符（|）来组合它们，但由于 Ly 的
            # 配置不支持使用该运算符，你必须手动计算颜色值。
            # 注意，如果你想使用终端的默认颜色值，可以使用特殊值 0x00000000。
            # 这意味着，如果你想使用黑色，*必须*使用样式选项 TB_HI_BLACK（使用此选项时 RGB 值将被忽略）。

            # 是否允许空密码进行身份验证
            allow_empty_password = true;

            # 活动的动画
            # none     -> 无
            # doom     -> PSX DOOM 火焰
            # matrix   -> CMatrix
            # colormix -> 颜色混合着色器
            # gameoflife -> 康威生命游戏
            # dur_file -> .dur 文件格式 (https://github.com/cmang/durdraw/tree/master)
            animation = "dur_file";

            # Dur file path
            dur_file_path = builtins.fetchurl {
              url = "https://codeberg.org/attachments/f336d6ac-8331-4323-91fc-0e4619803401";
              sha256 = "1n4vnwdzcbmdrs4f3yp0d65vy0cx0hrknhdm5sfz3xrab71b86bx";
            };

            # 在左上角显示的电量标识
            # 主电池通常是 BAT0 或 BAT1
            # 如果设置为 null，将不显示电池状态
            battery_id = "BAT1";

            # 更改大时钟的状态和语言
            # none -> 禁用（默认）
            # en   -> 英语
            # fa   -> 波斯语
            bigclock = "en";

            # 大时钟显示秒数
            bigclock_seconds = true;

            # 降低亮度的命令
            brightness_down_cmd = "${pkgs.brightnessctl}/bin/brightnessctl -q -n s 10%-";

            # 降低亮度的按键组合，或设置为 null 以禁用
            brightness_down_key = "F5";

            # 增加亮度的命令
            brightness_up_cmd = "${pkgs.brightnessctl}/bin/brightnessctl -q -n s +10%";

            # 增加亮度的按键组合，或设置为 null 以禁用
            brightness_up_key = "F6";

            # 失败时清除密码输入
            clear_password = true;

            # 是否渲染真彩色（如果支持）
            # 如果为 false，输出将使用八色模式
            # 所有八色模式颜色代码：
            # TB_DEFAULT              0x0000
            # TB_BLACK                0x0001
            # TB_RED                  0x0002
            # TB_GREEN                0x0003
            # TB_YELLOW               0x0004
            # TB_BLUE                 0x0005
            # TB_MAGENTA              0x0006
            # TB_CYAN                 0x0007
            # TB_WHITE                0x0008
            # 如果关闭全彩色，样式选项仍然有效。颜色始终是
            # 32 位值，样式在最高有效字节中。
            # 注意：如果使用 dur_file 动画选项并且 dur 文件颜色范围
            # 保存为 256 且此选项禁用，文件将不会被绘制。
            full_color = true;

            # 按下休眠键时执行的命令（可以为 null）
            hibernate_cmd = "/run/current-system/systemd/bin/systemctl suspend-then-hibernate";

            # 指定用于休眠的按键组合
            hibernate_key = "F4";

            # 当一段时间内没有检测到输入时执行的命令
            # 如果为 null，则不执行任何命令
            inactivity_cmd = "/run/current-system/systemd/bin/systemctl suspend";

            # 在指定秒数后执行命令
            inactivity_delay = 300;

            # 通用日志文件路径
            # 如果为 null，将改用 syslog
            ly_log = "/var/log/ly.log";

            # 按下重启键时执行的命令
            restart_cmd = "/run/current-system/systemd/bin/systemctl reboot";

            # 指定用于重启的按键组合
            restart_key = "F2";

            # 保存当前桌面和登录作为默认值，并在启动时加载它们
            save = true;

            # 服务名称（设置为 ly 以使用提供的 PAM 配置文件）
            service_name = "ly";

            # 指定用于显示密码的按键组合
            show_password_key = "F7";

            # 在右上角时钟右侧显示活动 TTY 编号（例如 tty3）
            # 如果时钟被禁用，TTY 标签将单独占据右上角
            # 如果为 false，将不显示 TTY 编号
            show_tty = false;

            # 按下关机键时执行的命令
            shutdown_cmd = "/run/current-system/systemd/bin/systemctl poweroff";

            # 指定用于关机的按键组合
            shutdown_key = "F1";

            # 按下睡眠键时执行的命令（可以为 null）
            sleep_cmd = "/run/current-system/systemd/bin/systemctl suspend";

            # 指定用于睡眠的按键组合
            sleep_key = "F3";
          };
        };
      };
  };
}
