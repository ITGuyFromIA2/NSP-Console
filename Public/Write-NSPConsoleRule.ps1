function Write-NSPConsoleRule {
    <#
    .SYNOPSIS
        Writes a section rule with an optional title: '  -- Title ------------'.
    .EXAMPLE
        Write-NSPConsoleRule -Title 'Policies'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][string]$Title,
        [ValidateRange(20, 1000)][int]$Width,
        [ValidateSet('Heading', 'Muted', 'Warning', 'Error', 'Success', 'Accent')][string]$Role = 'Heading'
    )

    if (-not $Width) { $Width = [Math]::Min((Get-NSPConsoleWidth), 200) }
    $start = if ($Title) { "  -- $Title " } else { '  ' }
    Write-NSPConsoleLine ($start.PadRight($Width - 1, '-')) -Role $Role
}
