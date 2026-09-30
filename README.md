# configs host template

This public repository is a starting point for a **private** repository that
owns multiple Unix-like hosts. `flake-modules/hosts/example.nix` is synthetic: its account,
hostname, and Git address are examples, and it has no secret recipient or
encrypted host value. The example consumes a pinned version of the
[`configs`](https://github.com/shk95/configs) provider API. The root source
and lock select delivered provider revision
`c76752dc1ec285dce721ae02a2f139c9f32dcb76`; this is an explicit source
adoption, separate from a future provider release tag. This revision includes
the native-default override and contract-inspection repair from provider PR #435.
The prior U1 source selection `3d6d945f1a7c32428ae506586eb5b644129e5614`
retains its original evaluation evidence; it does not certify this pin.

Create one private repository from this template. Keep one root `flake.nix`
and `flake.lock`; add one explicit declaration per host under
`flake-modules/hosts/`. Each declaration chooses a public constructor and
passes native `systemModules` and `homeModules`. The connection module creates
final outputs and optional comparison declarations from the same inputs.
`tool/check-hosts` evaluates every declared output. Each host still chooses
when to build and activate its own configuration. Template improvements are
copied into an existing private repository by review, never synchronized
automatically.

Each declaration calls one of `configs.lib.mkNixos`, `mkDarwin`, or `mkHome`.
`system`, `user`, `git`, and `environment` select the provider environment;
the output name, hostname, account creation, storage and access policy remain
host-owned. `mkHome` also requires the actual `homeDirectory` and accepts no
`systemModules`. Omitted `environment` selects the provider defaults. The
contract is at `api/contract.json` in the pinned `configs` Unix-like source.
Set `CONFIGS_PROVIDER_OVERRIDE` to a candidate Unix-like flake path when
running `tool/check-hosts` to check an exact pair without changing this lock.

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
