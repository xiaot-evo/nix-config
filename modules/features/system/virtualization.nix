{ ... }:
{
  den.aspects.system.virtualization =
    { host, ... }:
    {
      homeManager = { pkgs, ... }: {
        home.packages = [ pkgs.virt-manager ];
      };

      provides.to-hosts.nixos =
        { pkgs, ... }:
        {
          virtualisation.libvirtd = {
            enable = true;
            qemu.package = pkgs.qemu_kvm;
          };
          users.groups.libvirtd.members = builtins.attrNames host.users;
        };
    };
}
