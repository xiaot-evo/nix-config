{ den, ... }:
{
  den.aspects.system.virtualization =
    { host, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          virtualisation.libvirtd = {
            enable = true;
            qemu.package = pkgs.qemu_kvm;
          };
          programs.virt-manager.enable = true;
          users.groups.libvirtd.members = builtins.attrNames host.users;

          # Podman — distrobox 依赖的容器运行时
          virtualisation.podman = {
            enable = true;
            # 兼容 docker CLI（docker -> podman 别名）
            dockerCompat = true;
            # 容器网络 DNS
            defaultNetwork.settings = {
              dns_enabled = true;
            };
          };

          # NVIDIA GPU 容器支持（CDI）
          hardware.nvidia-container-toolkit.enable = true;
        };
    };
}
