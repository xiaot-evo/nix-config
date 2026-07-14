{ den, ... }:
{
  den.aspects.dev.tools.distrobox = {
    homeManager = { pkgs, ... }: {
      programs.distrobox = {
        enable = true;
        # 全局设置（所有容器继承）
        settings = {
          # 容器默认使用的主目录路径
          # container_user_custom_home = "/home/xiaot_evo/.distrobox/custom_home";
          # 额外的卷挂载
          # container_additional_volumes = "/home/xiaot_evo/projects:/projects:ro";
          # 始终拉取最新镜像
          # container_always_pull = "1";
        };
        # 容器定义（示例，按需取消注释）
        containers = {
          # Arch Linux 容器
          arch = {
            image = "quay.io/toolbx/arch-toolbox:latest";
            additional_packages = "git vim neovim";
            init = true;
            unshare_all = true;
          };
          # Ubuntu 容器（用于构建和测试）
          ubuntu = {
            image = "quay.io/toolbx/ubuntu-toolbox:26.04";
            additional_packages = "build-essential git curl";
            init = false;
          };
        };
        # 当容器配置变更时自动重建（定义容器后可设为 true）
        enableSystemdUnit = true;
      };
    };
  };
}
