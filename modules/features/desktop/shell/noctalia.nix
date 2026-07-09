{ den, inputs, ... }:
{
  den.aspects.desktop.shell.noctalia = {
    homeManager = {
      imports = [ inputs.noctalia.homeModules.default ];
      # programs.noctalia.enable = true;  # 取消注释启用
    };
  };
}
