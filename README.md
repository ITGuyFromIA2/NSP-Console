# NSP.Console

Small console helpers for interactive PowerShell tools. The module supports Windows
PowerShell 5.1 and PowerShell 7. It has no dependency on `NSP.Bootstrap` or any domain tool.

```powershell
Import-Module .\NSP.Console.psd1

Write-NSPConsoleLine 'Saved.' -Role Success
Write-NSPConsoleLine 'Review this setting.' -Role Warning

$selection = Read-NSPChoice -Prompt 'Select an option' -Choices @(
    [pscustomobject]@{ Label = 'First option'; Value = 'first' }
    [pscustomobject]@{ Label = 'Second option'; Value = 'second' }
)

if (Read-NSPConfirm -Prompt 'Continue?') {
    # The calling tool performs its own action.
}
```

`Write-NSPConsoleLine` maps semantic roles to Windows console colors and accepts
`-ForegroundColor` when a screen needs a specific color. The words in each message must
remain meaningful without color. Commands that produce data should return objects; these
helpers write only operator-facing presentation to the host.

`Read-NSPChoice` returns the selected item's `Value`, not its display number. An invalid
answer retries by default. `-InvalidSelectionAction ReturnNull` reports it once and returns
to the caller, useful when an outer menu owns navigation. Q cancels and returns `$null`.
`Read-NSPConfirm` defaults to no; `-DefaultYes` changes the blank-answer default.
`-Selection` and `-Answer` allow callers with an existing noninteractive response.

`Read-NSPNonEmpty` asks until it gets a value; with `-CurrentValue`, a blank answer keeps it.
`Read-NSPOptional` asks once and may return blank, or `-Default`. With `-AllowBack`, both
return a back signal when the operator types B or Back; check it with `Test-NSPBackSignal`:

```powershell
$ou = Read-NSPNonEmpty -Prompt 'Target OU' -AllowBack
if (Test-NSPBackSignal $ou) { return }
```

`Read-NSPMenu` is for screens with more than a plain list. Choices are numbered in order
unless they carry a `Key` (such as `N` for New), may carry a muted `Help` line and a `Section`
title, and `-Inline` lays them across the line under a dashboard. Keys are shown yellow.

```powershell
Clear-NSPConsole
Write-NSPConsoleHeader -Title 'Tool name' -Subtitle 'contoso.example'
Write-NSPConsoleSegment -Segment @(@('  Session   ', 'Muted'), @('signed in', 'Success'))
Write-NSPConsoleRule -Title 'Status'
$task = Read-NSPMenu -Prompt 'What do you want to do?' -Choices @(
    [pscustomobject]@{ Label = 'Add travel'; Value = 'travel'; Help = 'Allow sign-ins from a country.' }
    [pscustomobject]@{ Key = 'N'; Label = 'New client'; Value = 'new' }
)
```

`Write-NSPConsoleLine` roles: Normal, Heading and Action (cyan), Success (green), Warning and
Key (yellow), Error (red), Muted (dark gray), Accent (magenta), and Strong (white).
`Clear-NSPConsole` does nothing when output is redirected, so logs and tests keep everything.

`Get-NSPConsoleColumnLayout` performs width calculations only. It does not render rows.
`Set-NSPConsoleMaximized` should be called at interactive startup while the intended
terminal has focus. It uses UI Automation and silently leaves unsupported hosts unchanged.

Run `tools\Test-Repo.ps1` for parser, module, and behavior checks in both PowerShell
versions. If PSScriptAnalyzer is installed, the runner checks it too. The repo contains
source only; integration copies and generated packages belong with their consuming tools.

## Publishing

`tools\Publish-ToGallery.ps1 -WhatIf` runs repository checks, stages the runtime files,
and validates the staged manifest without reading an API key or publishing. A real run
requires Microsoft.PowerShell.PSResourceGet and `NSP.Bootstrap` for `Get-NSPSecret`.
Use `-BootstrapManifest <path>` if Bootstrap is available only as a local checkout.
Review the staged version and manifest before a real publish run; Gallery versions cannot
be overwritten in place.
