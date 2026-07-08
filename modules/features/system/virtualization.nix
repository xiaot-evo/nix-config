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
          environment.systemPackages = [ pkgs.virt-manager ];
          users.groups.libvirtd.members = builtins.attrNames host.users;
        };
    };
}
