{ inputs, den, ... }:
{
  # DankSearch (dsearch) — danklinux 生态的索引文件搜索服务
  # DMS Spotlight 启动器检测到 dsearch 服务后自动启用文件搜索
  den.aspects.desktop.shell.dms-shell.danksearch = {
    homeManager =
      { config, ... }:
      {
        imports = [ inputs.danksearch.homeModules.dsearch ];
        programs.dsearch = {
          enable = true;
          # 写入 ~/.config/danksearch/config.toml
          config = {
            index_paths = [
              {
                path = config.home.homeDirectory;
                max_depth = 6;
                exclude_hidden = true;
                # 保留内置噪音目录排除列表（node_modules, .cache, .venv, .git 等）
                merge_default_exclude_dirs = true;
                exclude_dirs = [ ];
              }
            ];
          };
        };
      };
  };
}
