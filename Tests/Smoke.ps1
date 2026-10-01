$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repoRoot 'NSP.Console.psd1'
$manifest = Test-ModuleManifest -Path $modulePath -ErrorAction Stop
if ($manifest.Name -ne 'NSP.Console') { throw 'The module manifest has the wrong name.' }
Import-Module $modulePath -Force -ErrorAction Stop

$expected = @(
    'Write-NSPConsoleLine', 'Read-NSPChoice', 'Read-NSPConfirm',
    'Get-NSPConsoleColumnLayout', 'Set-NSPConsoleMaximized',
    'Read-NSPMenu', 'Write-NSPConsoleHeader', 'Write-NSPConsoleRule',
    'Write-NSPConsoleSegment', 'Get-NSPConsoleWidth', 'Clear-NSPConsole'
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

    $menu = @(
        [pscustomobject]@{ Label = 'Add travel'; Value = 'travel'; Help = 'Allow a country for a while.'; Section = 'Tasks' }
        [pscustomobject]@{ Label = 'Plan policies'; Value = 'plan' }
        @{ Key = 'N'; Label = 'New tenant'; Value = 'new' }
    )
    $script:hostCalls.Clear()
    $script:answers.Enqueue('x')
    $script:answers.Enqueue('n')
    if ((Read-NSPMenu -Choices $menu) -ne 'new') { throw 'A lettered key did not select its entry after a retry.' }
    # A blank line separates the numbered list from the lettered options, once.
    $texts = @($script:hostCalls | ForEach-Object { $_.Text })
    $nIndex = [array]::IndexOf($texts, '  N. ')
    if ($nIndex -lt 1 -or $texts[$nIndex - 1] -ne '' -or @($texts | Where-Object { $_ -eq '' }).Count -ne 1) {
        throw "The lettered options are not set apart from the numbered list by one blank line: $($texts -join '|')"
    }
    if (-not @($script:hostCalls | Where-Object { $_.Text -match '^\s+N\. $' -and $_.Color -eq 'Yellow' }).Count) { throw 'Menu keys are not in the Key color.' }
    if (-not @($script:hostCalls | Where-Object { $_.Text -match 'Allow a country' -and $_.Color -eq 'DarkGray' }).Count) { throw 'Help lines are not shown muted.' }
    $script:answers.Enqueue('2')
    if ((Read-NSPMenu -Choices $menu -Inline) -ne 'plan') { throw 'Numbers do not follow the unkeyed entries.' }
    if ($null -ne (Read-NSPMenu -Choices $menu -Answer 'Q')) { throw 'Q did not cancel the menu.' }
    if ((Read-NSPMenu -Choices $menu -Answer '1') -ne 'travel') { throw '-Answer did not select.' }
    $threw = $false
    try { Read-NSPMenu -Choices @(@{ Key = 'Q'; Label = 'x'; Value = 1 }) -Answer 'Q' } catch { $threw = $true }
    if (-not $threw) { throw 'A choice may not use the cancel key.' }

    $script:hostCalls.Clear()
    Write-NSPConsoleSegment -Segment @('plain ', @('ok', 'Success'), @{ Text = 'long value'; Role = 'Accent'; Width = 6 })
    $texts = @($script:hostCalls | ForEach-Object { $_.Text })
    if ($texts[0] -ne 'plain ' -or $script:hostCalls[1].Color -ne 'Green' -or $texts[2] -ne 'long..' -or $script:hostCalls[2].Color -ne 'Magenta') {
        throw "Segments were not written in order with their colors and widths: $($texts -join '|')"
    }
    $script:hostCalls.Clear()
    Write-NSPConsoleHeader -Title 'Title' -Subtitle 'tenant.example' -Width 40
    if ($script:hostCalls[0].Text.Length -ne 39 -or -not @($script:hostCalls | Where-Object { $_.Text -eq 'tenant.example' }).Count) { throw 'The header is not sized or does not show the subtitle.' }
    $script:hostCalls.Clear()
    Write-NSPConsoleRule -Title 'Policies' -Width 30
    if ($script:hostCalls[0].Text -ne ('  -- Policies '.PadRight(29, '-'))) { throw "Rule rendered as '$($script:hostCalls[0].Text)'." }
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
