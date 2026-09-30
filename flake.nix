{
  description = "Synthetic single-flake Unix-like host repository";

  inputs = {
    # Explicitly adopt the delivered U1 provider source, independently of a release tag.
    configs.url = "github:shk95/configs/3d6d945f1a7c32428ae506586eb5b644129e5614?dir=unixlike";
    nixpkgs.follows = "configs/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts/31729ca8cbdb4fa927b34e5f4353e6a83f39e993";
    import-tree.url = "github:vic/import-tree/eb1b52eaecc57f7c136d07ae8a93e724dfecac46";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./flake-modules);
}
