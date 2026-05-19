# defines all hosts + users + homes.
# then config their aspects in as many files you want
{
  # tux user at igloo host.
  den.hosts.x86_64-linux.igloo.users.tux = { };

  # xiaot_evo user at nixos host
  den.hosts.x86_64-linux.acer-swift.users.xiaot_evo = { };

  # define an standalone home-manager for tux
  # den.homes.x86_64-linux.tux = { };
  den.homes.x86_64-linux.xiaot_evo = { };

  # be sure to add nix-darwin input for this:
  # den.hosts.aarch64-darwin.apple.users.alice = { };

  # other hosts can also have user tux.
  # den.hosts.x86_64-linux.south = {
  #   wsl = { }; # add nixos-wsl input for this.
  #   users.tux = { };
  #   users.orca = { };
  # };
}
