$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repoRoot 'NSP.Console.psd1'
$manifest = Test-ModuleManifest -Path $modulePath -ErrorAction Stop
if ($manifest.Name -ne 'NSP.Console') { throw 'The module manifest has the wrong name.' }
Import-Module $modulePath -Force -ErrorAction Stop

$expected = @(
    'Write-NSPConsoleLine', 'Read-NSPChoice', 'Read-NSPConfirm',
    'Get-NSPConsoleColumnLayout', 'Set-NSPConsoleMaximized'
)
$actual = @(Get-Command -Module NSP.Console | Select-Object -ExpandProperty Name)
if (@(Compare-Object $expected $actual).Count) { throw 'The exported command set differs from the manifest.' }

$choices = @(
    [pscustomobject]@{ Label = 'First'; Value = 'stable-a' },
    [pscustomobject]@{ Label = 'Second'; Value = 'stable-b' }
)
if ((Read-NSPChoice -Choices $choices -Selection 2) -ne 'stable-b') {
    throw 'Selection did not return its stable value.'
}
if (-not (Read-NSPConfirm -Prompt 'Continue?' -Answer '' -DefaultYes)) {
    throw 'Blank answer did not use the selected default.'
}

$script:answers = [System.Collections.Generic.Queue[string]]::new()
$script:hostCalls = [System.Collections.Generic.List[object]]::new()
function global:Read-Host {
    param([string]$Prompt)
    if ($script:answers.Count -eq 0) { throw "Unexpected prompt: $Prompt" }
    $script:answers.Dequeue()
}
function global:Write-Host {
    param($Object, $ForegroundColor, [switch]$NoNewline)
    $script:hostCalls.Add([pscustomobject]@{
        Text = [string]$Object
        Color = [string]$ForegroundColor
        NoNewline = [bool]$NoNewline
    })
}
try {
    Write-NSPConsoleLine 'Completed.' -Role Success
    Write-NSPConsoleLine 'Heading' -Role Heading -ForegroundColor DarkCyan
    if ($script:hostCalls[0].Color -ne 'Green' -or $script:hostCalls[1].Color -ne 'DarkCyan') {
        throw 'Role colors or explicit override were not forwarded to the host.'
    }
    $script:answers.Enqueue('bad')
    $script:answers.Enqueue('2')
    if ((Read-NSPChoice -Choices $choices) -ne 'stable-b') { throw 'Retry did not select the item.' }
    $script:answers.Enqueue('bad')
    if ($null -ne (Read-NSPChoice -Choices $choices -InvalidSelectionAction ReturnNull)) {
        throw 'ReturnNull did not return after an invalid choice.'
    }
    $script:answers.Enqueue('q')
    if ($null -ne (Read-NSPChoice -Choices $choices)) { throw 'Q did not cancel selection.' }
    $script:answers.Enqueue('maybe')
    $script:answers.Enqueue('yes')
    if (-not (Read-NSPConfirm -Prompt 'Continue?')) { throw 'Confirmation did not retry.' }
    if ($script:answers.Count -ne 0) { throw 'A mocked answer was left unread.' }
}
finally {
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
    Remove-Item Function:\Write-Host -ErrorAction SilentlyContinue
}

foreach ($width in 40, 80, 120, 200) {
    $layout = Get-NSPConsoleColumnLayout -ConsoleWidth $width -MaxLabelLength 30
    if ($layout.ColumnWidth -gt ($width - 3) -or $layout.RuleWidth -gt ($width - 3)) {
        throw "Column layout overflows a $width-character console."
    }
}

# Exercise graceful failure without changing an actual desktop window.
function global:Add-Type { throw 'UI Automation unavailable' }
try { Set-NSPConsoleMaximized }
finally { Remove-Item Function:\Add-Type -ErrorAction SilentlyContinue }

"PowerShell $($PSVersionTable.PSVersion): NSP.Console smoke checks passed."
