{ den, ... }:
{
  den.aspects.dev.tools.git = {
    homeManager = { ... }: {
      programs.git = {
        enable = true;
        settings = {
          user.name = "xiaot-evo";
          user.email = "3258412091@qq.com";
        };
      };
    };
  };
}
