{
  programs.helix.settings = {
    # theme = "catppuccin_macchiato";
    theme = {
      light = "catppuccin_latte";
      dark = "catppuccin_macchiato";
    };
    editor = {
      bufferline = "multiple";
      color-modes = true;
      cursorcolumn = true;
      cursorline = true;
      line-number = "absolute";
      mouse = false;
    };
    editor.cursor-shape = {
      insert = "bar";
      normal = "block";
      select = "underline";
    };
    editor.file-picker.hidden = false;

    editor.lsp.display-messages = true;

    editor.statusline = {
      center = [ "file-name" ];
      left = [
        "mode"
        "spinner"
      ];
      right = [
        "diagnostics"
        "selections"
        "position"
        "file-encoding"
        "file-line-ending"
        "file-type"
      ];
      separator = "│";
    };
    editor.statusline.mode = {
      insert = "INSERT";
      normal = "NORMAL";
      select = "SELECT";
    };
    keys.insert.A-j = "normal_mode";

    keys.normal = {
      C-e = [
        "scroll_down"
        "move_line_down"
      ];
      C-y = [
        "scroll_up"
        "move_line_up"
      ];
      esc = [
        "collapse_selection"
        "keep_primary_selection"
      ];
    };
    keys.normal.space = {
      q = ":q";
      w = ":w";
    };
    keys.select.A-j = "normal_mode";
  };
}
