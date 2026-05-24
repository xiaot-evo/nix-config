{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.git = inputs.wrappers.wrappers.git.wrap {
        inherit pkgs;
        settings = {
          user = {
            name = "xiaot-evo";
            email = "3258412091@qq.com";
          };
        };
      };
    };
}
