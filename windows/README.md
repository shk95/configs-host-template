# Windows host template

Copy the contents of this directory to a separate private Windows consumer
repository. No Nix tooling is needed. The sibling Unix-like template is independent;
its flake, lock and modules are not required in the Windows consumer.

## Provider pin and selection

Adopted tag: `windows-v1.0.0`.
Exact commit: `ca2da420882c6479f393cec22b6113c84da0fee4`.

`environment.json` is the authoritative SHA pin. It explicitly enables all six
features and all 28 managed file units in this release, using provider defaults.
Tag movement does not change the pin. New releases and newly offered options
require explicit adoption and selection review. There are no private identities
or settings in this example. This release does not offer host-global .wslconfig
or personal FancyZones layouts and layout hotkeys.

## Native Windows commands

Use PowerShell 7 with Git available:

```powershell
.\host.ps1 prepare
.\host.ps1 build
.\host.ps1 check
```

Run commands individually and continue only after a successful prepare/build.
Prepare downloads a provider checkout at the declared SHA on first use; later
runs verify it without fetching or updating source. Dirty or mismatched checkouts
are refused. The pinned provider's inspect output describes its consumer contract.
Build invokes that provider's generator; it requires native payload parsers and
does not install missing prerequisites or Apply settings.

Provider checkouts are cached under
`%LOCALAPPDATA%\configs-hosts-windows\providers\<SHA>`. Generations are under
`%LOCALAPPDATA%\configs-hosts-windows\hosts\<consumer-path-hash>\current`, outside
host originals and provider source. Moving the consumer requires a new build.
Check and Apply use the generated entry point and its integrity validation.
Provider commands' exit statuses pass through: Check returns 0 converged, 2 drift,
69 unverified, or 1 failed. The launcher reports its own failures as 1.

Only when applying to this host is explicitly intended:

```powershell
.\host.ps1 apply
```

Apply can install packages and write managed host files. It does not implicitly
prepare or build. Changing declarations, connected settings or the pin requires
build before Check or Apply. Existing unmanaged application state is preserved
according to each provider unit's contract.

## Customization and evidence

For complete host-owned settings, add an explicit relative document connection
and use the pinned provider's settings format. Provider defaults are not merged
into host content. Capture previews originals; explicit Save writes them.
Consult `windows/examples/README.md` in the pinned provider for details.

No AGENTS.md is supplied. In the configs workspace, Context Bridge links this
template, provider contract and private consumer. Copies own their source and
adopt later template changes explicitly, without synchronization.

Native generation, client Check and Apply remain unverified. Provider release CI
qualifies its fixtures, not this consumer on a real host. The initial client
baseline is Windows 10 IoT Enterprise LTSC 21H2 x64 build 19044; Windows 11
qualification is separate. Apply has not been performed.
