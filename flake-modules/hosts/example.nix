_: {
  hosts.example = {
    constructor = "mkNixos";
    inputs = {
      system = "x86_64-linux";
      user = "example";
      git = {name = "Example"; email = "example@example.invalid";};
      environment.graphical = false;
    };
    systemModules = [{
      networking.hostName = "example";
      users.users.example.isNormalUser = true;
      fileSystems."/" = {
        device = "/dev/disk/by-label/example";
        fsType = "ext4";
      };
      boot.loader.grub.enable = false;
    }];
    homeModules = [{
      home.sessionVariables.EXAMPLE_HOST = "example";
    }];
  };
}
