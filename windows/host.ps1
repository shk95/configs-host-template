#Requires -Version 7.0
<#
.SYNOPSIS
Prepares a pinned provider, builds a generation, checks or explicitly applies it.
.DESCRIPTION
Run prepare, then build, then check under native Windows PowerShell 7.
Capture previews by default; explicit Save writes host originals.
Only apply changes managed host state. Commands never update the declared pin.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('prepare', 'build', 'check', 'apply', 'capture', 'inspect', 'export-selection', 'units', 'help')]
    [string] $Command,
    [string[]] $Unit,
    [string[]] $Document,
    [switch] $Save,
    [string] $State
)

$ErrorActionPreference = 'Stop'
try {
    foreach ($name in @('Unit', 'Document', 'Save', 'WhatIf', 'Confirm')) {
        if ($PSBoundParameters.ContainsKey($name) -and $Command -ne 'capture') {
            throw "-$name is accepted only with capture."
        }
    }
    if ($PSBoundParameters.ContainsKey('State') -and $Command -ne 'export-selection') {
        throw '-State is accepted only with export-selection.'
    }
    if ($Command -eq 'help') {
        @'
Usage: .\host.ps1 <command> [options]
  prepare          acquire/verify the declared provider SHA; print its contract
  inspect          read the prepared provider contract without network access
  units            list offered units and this declaration's management/source
  build            generate selected desired state; no Apply
  check            inspect the existing generation; read-only
  apply            explicitly apply the existing generation to this host
  capture          preview explicitly selected/enabled app units into host originals
                   -Unit <IDs> [-Document <relative paths>] [-Save] [-WhatIf]
  export-selection print a legacy selection proposal; optional -State <file>
  help             print this help; no Windows or provider prerequisite
First capture requires Document; subsequent capture uses its existing connection.
Save writes originals and connections, never Apply or Git. Rebuild after saving.
Prerequisites: native Windows PowerShell 7; Git for provider access; build also
needs the selected payload parsers (all-option template: Lua compiler and Zellij).
Check returns provider statuses unchanged: 0 converged, 2 drift, 69 unverified.
'@ | Write-Output
        exit 0
    }
    if (-not $IsWindows) { throw 'Run this consumer under native Windows PowerShell 7.' }
    if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is required.' }
    $environmentPath = Join-Path $PSScriptRoot 'environment.json'
    $environment = Get-Content -LiteralPath $environmentPath -Raw -Encoding utf8 | ConvertFrom-Json
    $commit = $environment.provider.commit
    if ($commit -isnot [string] -or $commit -cnotmatch '\A[0-9a-f]{40}\z') {
        throw 'environment.provider.commit must be a full lowercase commit SHA.'
    }
    # Cache outside host originals so generation and provider never overlap them.
    $rootBytes = [Text.Encoding]::UTF8.GetBytes([IO.Path]::GetFullPath($PSScriptRoot).ToLowerInvariant())
    $hostId = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($rootBytes)).Substring(0, 16).ToLowerInvariant()
    $cache = Join-Path $env:LOCALAPPDATA 'configs-hosts-windows'
    $provider = Join-Path $cache "providers\$commit"
    $generation = Join-Path $cache "hosts\$hostId\current"

    function Invoke-ProviderGit {
        param([string[]] $GitArguments)
        $result = & git @GitArguments
        if ($LASTEXITCODE -ne 0) { throw "Git failed: $($GitArguments -join ' ')" }
        return $result
    }

    function Assert-Provider {
        if (-not (Test-Path -LiteralPath (Join-Path $provider '.git'))) {
            throw 'Provider checkout is missing; run prepare first.'
        }
        $actual = Invoke-ProviderGit -GitArguments @('-C', $provider, 'rev-parse', 'HEAD')
        if ($actual -cne $commit) { throw 'Provider checkout does not match the declared pin.' }
        $dirty = Invoke-ProviderGit -GitArguments @('-C', $provider, 'status', '--porcelain', '--untracked-files=all')
        if ($dirty) { throw 'Provider checkout is dirty; preserve changes and repair it before continuing.' }
    }

    switch ($Command) {
        'prepare' {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is required for prepare.' }
            if (-not (Test-Path -LiteralPath $provider)) {
                $parent = Split-Path -Parent $provider
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
                $temporary = Join-Path $parent ('.prepare-' + [guid]::NewGuid().ToString('N'))
                try {
                    Invoke-ProviderGit -GitArguments @('clone', '--no-checkout', '--filter=blob:none', 'https://github.com/shk95/configs.git', $temporary) | Out-Host
                    Invoke-ProviderGit -GitArguments @('-C', $temporary, 'checkout', '--detach', $commit) | Out-Host
                    Move-Item -LiteralPath $temporary -Destination $provider
                }
                finally {
                    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
                }
            }
            Assert-Provider
            & (Join-Path $provider 'windows\win-env.ps1') inspect -SourceRoot $provider
            exit $LASTEXITCODE
        }
        'inspect' {
            Assert-Provider
            & (Join-Path $provider 'windows\win-env.ps1') inspect -SourceRoot $provider
            exit $LASTEXITCODE
        }
        'units' {
            Assert-Provider
            $json = & (Join-Path $provider 'windows\win-env.ps1') inspect -SourceRoot $provider
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            $contract = ($json -join "`n") | ConvertFrom-Json -AsHashtable
            $declaration = Get-Content -LiteralPath $environmentPath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
            $features = @{}
            foreach ($feature in $contract.features) { $features[$feature.Id] = $feature }
            $selected = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            $pending = [Collections.Generic.Queue[string]]::new()
            foreach ($id in $declaration.features) { $pending.Enqueue($id) }
            foreach ($feature in $contract.features) {
                if ($feature.Required) { $pending.Enqueue($feature.Id) }
            }
            while ($pending.Count) {
                $id = $pending.Dequeue()
                if (-not $features.ContainsKey($id)) { throw "Unknown selected feature '$id'." }
                if ($selected.Add($id)) {
                    foreach ($dependency in $features[$id].Requires) { $pending.Enqueue($dependency) }
                }
            }
            $rows = foreach ($unitInfo in $contract.units) {
                $entry = $declaration.units[$unitInfo.id]
                $isSelected = $selected.Contains($unitInfo.feature)
                $enabled = -not $entry -or $entry.enabled -eq $true
                $source = 'configs'
                $document = if ($entry) { $entry.document } else { $null }
                if ($document) {
                    # Resolve connected originals using the pinned provider's path contract.
                    Import-Module (Join-Path $provider 'windows\src\WinEnvGeneration.psm1')
                    $path = Resolve-WinEnvContractPath -Root $PSScriptRoot -Relative $document
                    $settings = Read-WinEnvContractJson $path
                    $source = $settings.source
                }
                [pscustomobject]@{
                    Unit = $unitInfo.id
                    Feature = $unitInfo.feature
                    Parser = $unitInfo.parser
                    Managed = ($isSelected -and $enabled)
                    Source = $source
                    Document = $document
                }
            }
            $rows | Sort-Object Feature, Unit | Format-Table -AutoSize -Wrap
            Write-Output 'Managed includes required features and dependencies. App presence and capture readiness are not checked.'
            exit 0
        }
        'capture' {
            if (-not $Unit.Count) { throw 'capture requires explicit -Unit IDs.' }
            Assert-Provider
            $arguments = @{ SourceRoot = $provider; Environment = $environmentPath; Unit = $Unit }
            if ($PSBoundParameters.ContainsKey('Document')) { $arguments.Document = $Document }
            $arguments.Save = [bool]$Save
            $arguments.WhatIf = [bool]$WhatIfPreference
            if ($PSBoundParameters.ContainsKey('Confirm')) { $arguments.Confirm = $PSBoundParameters.Confirm }
            & (Join-Path $provider 'windows\win-env.ps1') capture @arguments
            exit $LASTEXITCODE
        }
        'export-selection' {
            Assert-Provider
            $arguments = @{ SourceRoot = $provider }
            if ($PSBoundParameters.ContainsKey('State')) { $arguments.State = $State }
            & (Join-Path $provider 'windows\win-env.ps1') export-selection @arguments
            exit $LASTEXITCODE
        }
        'build' {
            Assert-Provider
            & (Join-Path $provider 'windows\win-env.ps1') generate -SourceRoot $provider -Environment $environmentPath -Output $generation
            exit $LASTEXITCODE
        }
        { $_ -in 'check', 'apply' } {
            $entry = Join-Path $generation 'windows\win-env.ps1'
            if (-not (Test-Path -LiteralPath $entry -PathType Leaf)) { throw 'Generation is missing; run build first.' }
            & $entry $Command -Generation $generation
            exit $LASTEXITCODE
        }
    }
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
