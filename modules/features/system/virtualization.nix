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
            # libvirt 的 ssh drop-in（/nix/store/.../ssh_config.d/30-libvirt-ssh-proxy.conf）
            # owner 为 nobody，导致 ssh 报 "Bad owner or permissions"，禁用该 Include
            sshProxy = false;
            qemu.package = pkgs.qemu_kvm;
          };
          programs.virt-manager.enable = true;
          # 仅授权本机用户管理虚拟机（原为全部主机用户，权限过宽）
          users.groups.libvirtd.members = [ "xiaot_evo" ];

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
          hardware.nvidia-container-toolkit = {
            enable = true;
            # 纯 Wayland（niri + XWayland Satellite）无 Xorg server，不设
            # services.xserver.videoDrivers；NVIDIA 驱动由 hardware.nvidia
            # （modesetting + prime offload）提供，抑制其驱动存在性断言
            suppressNvidiaDriverAssertion = true;
          };
        };
    };
}
