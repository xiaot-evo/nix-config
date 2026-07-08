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
        };
    };
}
