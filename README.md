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
