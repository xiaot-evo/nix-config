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
          x11Support = true;
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
            animation = "colormix";

            # 每帧动画之间的延迟（毫秒）
            animation_frame_delay = 5;

            # 一段时间后停止动画
            # 0 -> 永久运行
            # 1..2e12 -> 在此秒数后停止动画
            animation_timeout_sec = 0;

            # 用于遮盖密码的字符
            # 你可以直接输入 UTF-8 字符（如 *），或使用 UTF-32 码点（例如 0x2022 表示圆点）
            # 如果为 null，密码将被隐藏
            # 注意：你可以使用转义符 \# 来表示 #
            asterisk = "*";

            # 在播放特殊动画之前的失败认证次数...... ;)
            # 如果设置为 0，该动画将永远不会被播放
            auth_fails = 10;

            # 在左上角显示的电量标识
            # 主电池通常是 BAT0 或 BAT1
            # 如果设置为 null，将不显示电池状态
            battery_id = "BAT1";

            # 自动登录配置
            # 此功能允许 Ly 在没有密码提示的情况下自动登录用户。
            # 重要提示：必须同时设置 auto_login_user 和 auto_login_session 才能生效。
            # 自动登录仅在启动时发生一次 - 注销后不会重新触发。

            # 用于自动登录的 PAM 服务名称
            # 默认服务 (ly-autologin) 使用 pam_permit 允许无需密码登录
            # 将自动使用适当的平台特定 PAM 配置 (ly-autologin)
            auto_login_service = "ly-autologin";

            # 自动启动的会话名称
            # 要查找可用的会话名称，请查看以下目录中的 .desktop 文件：
            #   - /usr/share/xsessions/（X11 会话）
            #   - /usr/share/wayland-sessions/（Wayland 会话）
            # 使用不带 .desktop 扩展名的文件名、文件中的 Name 字段或 DesktopNames 字段的值
            # 示例："i3", "sway", "gnome", "plasma", "xfce"
            # 如果为 null，自动登录将被禁用
            auto_login_session = null;

            # 自动登录的用户名
            # 必须是系统上的有效用户
            # 如果为 null，自动登录将被禁用
            auto_login_user = null;

            # 背景颜色 ID
            bg = "0x00000000";

            # 更改大时钟的状态和语言
            # none -> 禁用（默认）
            # en   -> 英语
            # fa   -> 波斯语
            bigclock = "en";

            # 将大时钟设置为 12 小时制
            bigclock_12hr = false;

            # 大时钟显示秒数
            bigclock_seconds = true;

            # 主框背景空白
            # 设置为 false 将使其透明
            blank_box = true;

            # 边框前景色 ID
            border_fg = "0x00FFFFFF";

            # 距离屏幕末端的相对水平位置
            # 默认值：0.5
            box_position_h = 0.5;

            # 距离屏幕底部的相对垂直位置
            # 默认值：0.4
            box_position_v = 0.4;

            # 主框顶部显示的标题
            # 如果设置为 null，则不显示
            box_title = null;

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

            # 右上角时钟的格式字符串（参见 strftime 规范）。示例：%c
            # 如果为 null，将不显示时钟
            clock = null;

            # CMatrix 动画前景色 ID
            cmatrix_fg = "0x0000FF00";

            # CMatrix 动画字符串头部颜色 ID
            cmatrix_head_col = "0x01FFFFFF";

            # CMatrix 动画最小码点。使用 16 位整数
            # 例如，对于日文字符，可以在此处使用 0x3000
            cmatrix_min_codepoint = "0x21";

            # CMatrix 动画最大码点。使用 16 位整数
            # 例如，对于日文字符，可以在此处使用 0x30FF
            cmatrix_max_codepoint = "0x7B";

            # 颜色混合动画第一种颜色 ID
            colormix_col1 = "0x00FF0000";

            # 颜色混合动画第二种颜色 ID
            colormix_col2 = "0x000000FF";

            # 颜色混合动画第三种颜色 ID
            colormix_col3 = "0x20000000";

            # 自定义绑定：每行自定义绑定的字符水平限制，超过后换行
            # 如果为 null，则默认为终端宽度
            custom_bind_width = null;

            # 自定义会话目录
            # 可以指定多个目录，
            # 例如 $CONFIG_DIRECTORY/ly/custom-sessions:$PREFIX_DIRECTORY/share/custom-sessions
            custom_sessions = "$CONFIG_DIRECTORY/ly/custom-sessions";

            # 启动时默认激活的输入框
            # 可用输入：info_line, session, login, password
            default_input = "login";

            # DOOM 动画火焰高度（1 到 9）
            doom_fire_height = 6;

            # DOOM 动画火焰扩散（0 到 4）
            doom_fire_spread = 2;

            # DOOM 动画自定义顶部颜色（低强度火焰）
            doom_top_color = "0x009F2707";

            # DOOM 动画自定义中间颜色（中强度火焰）
            doom_middle_color = "0x00C78F17";

            # DOOM 动画自定义底部颜色（高强度火焰）
            doom_bottom_color = "0x00FFFFFF";

            # Dur 文件路径
            dur_file_path = "$CONFIG_DIRECTORY/ly/example.dur";

            # Dur 文件对齐方式
            # dur 文件可以按方向对齐，并通过以下标志轻松居中
            # 可用输入：topleft, topcenter, topright, centerleft, center, centerright, bottomleft, bottomcenter, bottomright
            dur_offset_alignment = "center";

            # Dur X 方向偏移（该值会添加到由对齐方式决定的当前位置，支持负值）
            dur_x_offset = 0;

            # Dur Y 方向偏移（该值会添加到由对齐方式决定的当前位置，支持负值）
            dur_y_offset = 0;

            # 设置边缘到 DM 的边距（适用于曲面显示器）
            edge_margin = 0;

            # 错误背景色 ID
            error_bg = "0x00000000";

            # 错误前景色 ID
            # 默认为红色加粗
            error_fg = "0x01FF0000";

            # 前景色 ID
            fg = "0x00FFFFFF";

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

            # 生命游戏熵间隔（0 = 禁用，>0 = 每 N 代增加熵）
            # 0 -> 纯康威生命游戏（最终会稳定下来）
            # 10 -> 每 10 代增加熵（推荐用于持续活动）
            # 50+ -> 较少频率的熵，更自然的演化
            gameoflife_entropy_interval = 10;

            # 生命游戏动画前景色 ID
            gameoflife_fg = "0x0000FF00";

            # 生命游戏帧延迟（越低动画越快，越高动画越慢）
            # 1-3 -> 非常快的动画
            # 6 -> 默认平滑动画速度
            # 10+ -> 较慢，更沉思的速度
            gameoflife_frame_delay = 6;

            # 生命游戏初始细胞密度（0.0 到 1.0）
            # 0.1 -> 稀疏，最小活性
            # 0.4 -> 平衡活性（推荐）
            # 0.7+ -> 密集，混乱的模式
            gameoflife_initial_density = 0.4;

            # 按下休眠键时执行的命令（可以为 null）
            hibernate_cmd = "systemctl suspend-then-hibernate";

            # 指定用于休眠的按键组合
            hibernate_key = "F4";

            # 移除主框边框
            hide_borders = false;

            # 移除电源管理命令提示
            hide_key_hints = false;

            # 从右上角移除键盘锁定状态
            hide_keyboard_locks = false;

            # 从左上角移除版本号
            hide_version_string = false;

            # 当一段时间内没有检测到输入时执行的命令
            # 如果为 null，则不执行任何命令
            inactivity_cmd = null;

            # 在指定秒数后执行命令
            inactivity_delay = 0;

            # 信息行的初始文本
            # 如果设置为 null，信息行默认为主机名
            initial_info_text = null;

            # 输入框长度
            input_len = 34;

            # 活动语言
            # 可用语言位于 $CONFIG_DIRECTORY/ly/lang/
            lang = "en";

            # 登录时执行的命令
            # 如果为 null，则不执行任何命令
            # 重要提示：代码本身必须以 `exec "$@"` 结尾才能启动会话！
            # 你也可以在其中设置环境变量，它们会持续到注销
            login_cmd = null;

            # login.defs 文件路径（用于在 Linux 上列出系统中所有本地用户）
            login_defs_path = "/etc/login.defs";

            # 注销时执行的命令
            # 如果为 null，则不执行任何命令
            # 重要：执行此命令时会话已结束，因此
            # 无需在末尾添加 `exec "$@"`
            logout_cmd = null;

            # 通用日志文件路径
            # 如果为 null，将改用 syslog
            ly_log = "/var/log/ly.log";

            # 主框水平边距
            margin_box_h = 2;

            # 主框垂直边距
            margin_box_v = 1;

            # 启动时设置 Numlock 开关
            numlock = false;

            # 默认路径
            # 如果为 null，Ly 不设置路径
            path = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";

            # 按下重启键时执行的命令
            restart_cmd = "/sbin/shutdown -r now";

            # 指定用于重启的按键组合
            restart_key = "F2";

            # 保存当前桌面和登录作为默认值，并在启动时加载它们
            save = true;

            # 服务名称（设置为 ly 以使用提供的 PAM 配置文件）
            service_name = "ly";

            # 会话日志文件路径
            # 这将包含 Wayland 会话的标准输出和标准错误
            # 默认保存在用户的主目录中
            # 重要提示：由于技术限制，X11、shell 会话以及通过 KMSCON 启动的会话不受支持，
            # 这意味着你不会从这些会话中获得任何日志。
            # 如果为 null，将不创建会话日志
            session_log = ".local/state/ly-session.log";

            # 设置命令
            setup_cmd = "$CONFIG_DIRECTORY/ly/setup.sh";

            # 在会话列表中显示 shell 会话
            # 如果为 false，shell 会话将被隐藏
            shell = true;

            # 指定用于显示密码的按键组合
            show_password_key = "F7";

            # 在右上角时钟右侧显示活动 TTY 编号（例如 tty3）
            # 如果时钟被禁用，TTY 标签将单独占据右上角
            # 如果为 false，将不显示 TTY 编号
            show_tty = false;

            # 按下关机键时执行的命令
            shutdown_cmd = "/sbin/shutdown $PLATFORM_SHUTDOWN_ARG now";

            # 指定用于关机的按键组合
            shutdown_key = "F1";

            # 按下睡眠键时执行的命令（可以为 null）
            sleep_cmd = "systemctl sleep";

            # 指定用于睡眠的按键组合
            sleep_key = "F3";

            # 启动 Ly 时执行的命令（在接管 TTY 之前）
            # 请参阅下面路径中的文件，了解更改默认 TTY 颜色的示例
            start_cmd = "$CONFIG_DIRECTORY/ly/startup.sh";

            # 居中显示会话名称
            text_in_center = false;

            # 默认 vi 模式
            # normal   -> 普通模式
            # insert   -> 插入模式
            vi_default_mode = "normal";

            # 启用 vi 键绑定
            vi_mode = false;

            # Wayland 桌面环境
            # 可以指定多个目录，
            # 例如 $PREFIX_DIRECTORY/share/wayland-sessions:$PREFIX_DIRECTORY/local/share/wayland-sessions
            # 如果为 null，将不显示 Wayland 会话
            waylandsessions = "$PREFIX_DIRECTORY/share/wayland-sessions";

            # Xorg 服务器命令
            # 添加 -quiet 参数以隐藏服务器启动日志
            x_cmd = "$PREFIX_DIRECTORY/bin/X";

            # Xorg 虚拟终端编号
            # 主要用于 FreeBSD，选择当前 TTY 会导致问题
            # 如果为 null，将选择当前 TTY
            x_vt = null;

            # Xorg xauthority 编辑工具
            xauth_cmd = "$PREFIX_DIRECTORY/bin/xauth";

            # xinitrc
            # 如果为 null，xinitrc 会话将被隐藏
            xinitrc = "~/.xinitrc";

            # Xorg 桌面环境
            # 可以指定多个目录，
            # 例如 $PREFIX_DIRECTORY/share/xsessions:$PREFIX_DIRECTORY/local/share/xsessions
            # 如果为 null，将不显示 X11 会话
            xsessions = "$PREFIX_DIRECTORY/share/xsessions";

            # 自定义命令和标签：
            # 以下示例说明了设置自定义命令和标签的大致方法。
            # 除非另有说明为可选，否则每个选项都是必填的。

            ## 使用 '##' 前缀的注释是文档说明。
            ## 使用 '#' 前缀的注释将示例 INI 注释掉。

            ## 使用 F8 绑定声明一个命令
            #cmd_f8 = {
            #  # 在 Ly 中显示的命令名称
            #  # 注意：locale 文件中的 "$brightness_up" 会被替换为相应的本地化字符串
            #  name = "custom command brightness_up";
            #  cmd = "touch /tmp/ly.gaming";
            #};

            ## 使用 ID 声明一个标签。此 ID 在所有标签中应唯一。
            #lbl_kernel = {
            #  cmd = "uname -srn";
            #  # 可选，默认为 0。
            #  # 以帧数为单位，重新运行命令并更新标签的时间。
            #  # 如果为 0，仅运行一次，之后不刷新。
            #  refresh = 0;
            #};
          };
        };
      };
  };
}
