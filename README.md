# configs host template

A starting point for a **private** repository managing Unix-like hosts with
[`configs`](https://github.com/shk95/configs). The provider version is pinned in
`flake.nix` and `flake.lock`.

For a native Windows consumer, copy only [`windows/`](windows/README.md).

## Getting started

Create a private repository from this template. With Nix installed, run:

```sh
nix develop
just                         # List commands
just check                   # Evaluate all declared hosts
just nixos-eval example       # Evaluate the synthetic example
```

The development shell includes `just`, `jq`, and `alejandra`, and supports
x86_64 Linux, aarch64 Linux, and Apple Silicon macOS. Use `just fmt` to format
Nix source, or `nix develop --command just check` to check without an interactive
shell.

## Host declarations

Replace [`flake-modules/hosts/example.nix`](flake-modules/hosts/example.nix)
with a real host declaration. Add one file per host under `flake-modules/hosts/`,
keeping one root flake and lock for the repository.

Each declaration selects `mkNixos`, `mkDarwin`, or `mkHome`, supplies provider
inputs, and adds native `systemModules` and `homeModules`. The declaration name
becomes the output name used by `just`. Hostnames, accounts, storage, and access
policy belong to this repository. Standalone `mkHome` requires `homeDirectory`
and accepts only `homeModules`.

See `api/contract.json` in the pinned provider source for the input contract.

## Build and activate

Use the command family matching the host declaration:

| Constructor | Evaluate | Build | Activate |
| --- | --- | --- | --- |
| `mkNixos` | `just nixos-eval <host>` | `just nixos-build <host>` | `just nixos-switch <host>` |
| `mkDarwin` | `just darwin-eval <host>` | `just darwin-build <host>` | `just darwin-switch <host>` |
| `mkHome` | `just home-eval <host>` | `just home-build <host>` | `just home-switch <host>` |

Evaluation does not build. Build prints store paths without creating a `result`
link. Activation is a separate, explicit command: review the real declaration
first and run it on the intended host, as the intended user for standalone
Home Manager. The included example is synthetic and must be replaced before
activation.

Darwin and Home Manager support first activation without an installed rebuild
command. NixOS uses the host's `nixos-rebuild`.

## Secrets and updates

Keep age private keys **outside the repository**, with an independent recovery
copy. Store real recipients only in the private repository and encrypt secret
values before committing them. The consumer owns its SOPS integration.

Review provider version and lock changes before adopting them. Copy template
improvements into existing consumers by review; they are not synchronized
automatically.
