{
  pkgs,
  lib,
  ...
}:
{
  # features = {
  #   copilot = false;
  # };
  # telemetry = {
  #   metrics = false;
  # };
  # vim_mode = false;
  # ui_font_size = 16;
  # buffer_font_size = 16;

  agent_servers = {
    pi-acp = {
      type = "registry";
    };
    OpenCode = {
      type = "custom";
      command = "opencode";
      args = [ "acp" ];
    };
  };
  terminal = {
    shell = {
      program = "${pkgs.fish}/bin/fish";
    };
  };
  # Tell Zed to use direnv and direnv can use a flake.nix environment
  load_direnv = "shell_hook";
  base_keymap = "VSCode";
  icon_theme = {
    mode = "system";
    light = "Catppuccin Latte";
    dark = "Catppuccin Macchiato";
  };
  theme = lib.mkForce {
    mode = "system";
    light = "Catppuccin Latte";
    dark = "Catppuccin Macchiato";
  };

  # 保存时格式化
  format_on_save = "on";
  # Helox Mode
  helix_mode = true;
}
