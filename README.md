# configs host template

This public repository is a starting point for a **private** repository that
owns multiple Unix-like hosts. `hosts/example` is synthetic: its account,
hostname, and Git address are examples, and it has no secret recipient or
encrypted host value. The example is evaluated in CI against a pinned version
of the [`configs`](https://github.com/shk95/configs) provider API.

Create one private repository from this template. Give each real host its own
`hosts/<name>/flake.nix` and `flake.lock`; copy and adapt the example or add a
new flake. The root `tool/check-hosts` evaluates every exported Home Manager,
NixOS, and nix-darwin output in every host directory. Host locks are updated
individually so one host can adopt a new provider revision without changing
the others. The generated repository owns its files: improvements to this
template are copied into it through an ordinary review, not synchronized
automatically.

Each host flake calls one of `configs.lib.mkNixos`, `mkDarwin`, or `mkHome`.
It provides host identity, Git identity, and explicit profile choices.
`mkNixos` and `mkDarwin` also accept `systemModules` and `homeModules` for
host-owned hardware facts and secret delivery; `mkHome` accepts `homeModules`.
The provider chooses its own machine and feature classes. See the example
flake for the constructor shape.

## SOPS and age boundary

The private repository decides which hosts need secrets, which age recipients
may decrypt them, and which SOPS module delivers them at activation time.
Create each age private key **outside the repository** and keep an independent
recovery copy. Record real recipients only in the private repository, encrypt
each value before committing it, and verify that plaintext does not enter Nix
evaluation or a build output. This public template contains no recipient,
private key, encrypted host value, or real host identity.

Evaluation and build check source configuration. Activation is a separate
host-specific operation and needs an explicit decision for that host.
