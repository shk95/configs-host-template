{
  description = "Synthetic host example for the configs provider API";

  inputs.configs.url = "github:shk95/configs/66fed0985e6cf6f8a8e5eab1cce4f1b7ab21d39d?dir=unixlike";

  outputs = {configs, ...}: {
    nixosConfigurations.example = configs.lib.mkNixos {
      name = "example";
      host = {
        system = "aarch64-linux";
        kind = "orbstack";
        user = "example";
        stateVersion = "25.11";
      };
      profiles = [];
      git = {
        name = "Example";
        email = "example@example.invalid";
      };
    };
  };
}
