{
  description = "Synthetic single-flake Unix-like host repository";

  inputs = {
    # Adopt unixlike-v1.0.0 at its immutable full source revision.
    configs.url = "https://api.github.com/repos/shk95/configs/tarball/ca2da420882c6479f393cec22b6113c84da0fee4?dir=unixlike";
    nixpkgs.follows = "configs/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts/31729ca8cbdb4fa927b34e5f4353e6a83f39e993";
    import-tree.url = "github:vic/import-tree/eb1b52eaecc57f7c136d07ae8a93e724dfecac46";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./flake-modules);
}
