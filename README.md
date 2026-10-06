# configs host template

This public repository is a starting point for a **private** repository that
owns multiple Unix-like hosts. `flake-modules/hosts/example.nix` is synthetic:
its account, hostname, and Git address are examples, and it has no secret
recipient or encrypted host value. The example consumes provider release
`unixlike-v1.0.0` from [`configs`](https://github.com/shk95/configs).
The root `flake.nix` and `flake.lock` explicitly pin full source revision
`ca2da420882c6479f393cec22b6113c84da0fee4`, so moving a branch or tag cannot
silently update the example. The explicit GitHub archive URL keeps source
hashing consistent across Nix fetchers with different Git line-ending
handling. The U1 transition and follow-up contract repair were reconstructed
against this release after the provider's history replacement. Earlier
unreleased-source evaluation does not certify this pin.

Create one private repository from this template. Keep one root `flake.nix`
and `flake.lock`; add one explicit declaration per host under
`flake-modules/hosts/`. Each declaration chooses a public constructor and
passes native `systemModules` and `homeModules`. The connection module creates
final outputs and `lib.hostDeclarations` inspection data from the same inputs.
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
running `tool/check-hosts` to check an exact pair. Run candidate-pair checks
in a linked worktree because Nix may update its lock.

## Release adoption evidence, 2026-10-06

Evaluation: `tool/check-hosts` passed against the committed source URL and
repository lock, including the example's final toplevel derivation.
Build and native runtime: not performed. Activation: not performed.
The provider release's qualification does not certify a deployed host.

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
