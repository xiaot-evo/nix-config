{ den, ... }:
{
  den.aspects.dev.tools.ollama = {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.ollama ];
    };
  };
}
