{
  description = "Synthetic host example for the configs provider API";

  inputs.configs.url = "github:shk95/configs/57d9bb6563957ca9463765d513d27571f5abc16d?dir=unixlike";

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
