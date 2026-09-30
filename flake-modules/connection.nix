{
  lib,
  config,
  inputs,
  ...
}: let
  inherit (lib) filterAttrs mapAttrs mkOption types;
  hostType = types.submodule {
    options = {
      constructor = mkOption {type = types.enum ["mkNixos" "mkDarwin" "mkHome"];};
      inputs = mkOption {type = types.attrs;};
      systemModules = mkOption {type = types.listOf types.deferredModule; default = [];};
      homeModules = mkOption {type = types.listOf types.deferredModule; default = [];};
    };
  };
  selected = constructor: filterAttrs (_: host: host.constructor == constructor) config.hosts;
  arguments = host:
    host.inputs
    // {inherit (host) homeModules;}
    // lib.optionalAttrs (host.constructor != "mkHome") {inherit (host) systemModules;};
  mk = constructor: _: host:
    if host.constructor == "mkHome" && host.systemModules != []
    then throw "standalone host declaration cannot set systemModules"
    else inputs.configs.lib.${constructor} (arguments host);
  declaration = host: {
    inherit (host) constructor;
    inputs = host.inputs;
    systemModules = host.systemModules != [];
    homeModules = host.homeModules != [];
  };
in {
  options.hosts = mkOption {
    type = types.attrsOf hostType;
    default = {};
    description = "Host declarations; each name selects one final output.";
  };
  options.flake.lib = mkOption {
    type = types.lazyAttrsOf types.anything;
    default = {};
  };
  config.flake = {
    nixosConfigurations = mapAttrs (mk "mkNixos") (selected "mkNixos");
    darwinConfigurations = mapAttrs (mk "mkDarwin") (selected "mkDarwin");
    homeConfigurations = mapAttrs (mk "mkHome") (selected "mkHome");
    lib.hostDeclarations = mapAttrs (_: declaration) config.hosts;
  };
}
