#Requires -Version 7.0
<#
.SYNOPSIS
Prepares a pinned provider, builds a generation, checks or explicitly applies it.
.DESCRIPTION
Run prepare, then build, then check under native Windows PowerShell 7.
Only apply changes managed host state. Commands never update the declared pin.
#>
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('prepare', 'build', 'check', 'apply')]
    [string] $Command
)

$ErrorActionPreference = 'Stop'
try {
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
