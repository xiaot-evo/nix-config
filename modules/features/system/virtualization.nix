{ ... }:
{
  den.aspects.system.virtualization = {
    nixos =
      { pkgs, ... }:
      {
        virtualisation.libvirtd = {
          enable = true;
          qemu.package = pkgs.qemu_kvm;
        };
        # 将用户加入 libvirtd 组以管理 VM
        users.groups.libvirtd.members = [ "xiaot_evo" ];
      };
  };
}
