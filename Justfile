# Consumer commands run against this repository's flake and lock.
set positional-arguments
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

default:
    @just --list

# Evaluate every declared host without building or activating.
check:
    tool/check-hosts

# Format this consumer's Nix source.
fmt:
    nix fmt .

# Evaluate one NixOS host; works from any development platform.
nixos-eval host:
    nix eval --raw "path:.#nixosConfigurations.${1}.config.system.build.toplevel.drvPath"

# Build without activating or creating a result symlink.
nixos-build host:
    nix build --no-link --print-out-paths "path:.#nixosConfigurations.${1}.config.system.build.toplevel"

# Activation: run on the intended NixOS host after reviewing its declaration.
nixos-switch host:
    test -e /etc/NIXOS
    sudo nixos-rebuild switch --flake "path:.#${1}"

darwin-eval host:
    nix eval --raw "path:.#darwinConfigurations.${1}.config.system.build.toplevel.drvPath"

darwin-build host:
    nix build --no-link --print-out-paths "path:.#darwinConfigurations.${1}.config.system.build.toplevel"

# Activation, including first setup without an installed darwin-rebuild.
darwin-switch host:
    #!/usr/bin/env bash
    set -euo pipefail
    test "$(uname -s)" = Darwin
    system=$(nix build --no-link --print-out-paths "path:.#darwinConfigurations.${1}.config.system.build.toplevel")
    sudo "${system}/sw/bin/darwin-rebuild" switch --flake "path:.#${1}"

home-eval host:
    nix eval --raw "path:.#homeConfigurations.${1}.activationPackage.drvPath"

home-build host:
    nix build --no-link --print-out-paths "path:.#homeConfigurations.${1}.activationPackage"

# Activation, including first setup without an installed home-manager.
home-switch host:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -e /etc/NIXOS ]; then
      echo 'Use nixos-switch for the Home Manager configuration composed into NixOS.' >&2
      exit 1
    fi
    generation=$(nix build --no-link --print-out-paths "path:.#homeConfigurations.${1}.activationPackage")
    "${generation}/activate"
