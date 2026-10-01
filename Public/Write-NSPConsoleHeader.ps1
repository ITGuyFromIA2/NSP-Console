function Write-NSPConsoleHeader {
    <#
    .SYNOPSIS
        Writes a screen banner: a rule, the title (with an optional right-aligned subtitle), a rule.
    .DESCRIPTION
        The width defaults to the console window, capped at 100 characters, so the banner
        does not wrap in a narrow window.
    .EXAMPLE
        Write-NSPConsoleHeader -Title 'Saved Answers' -Subtitle 'contoso.example'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Title,
        [string]$Subtitle,
        [ValidateRange(20, 1000)][int]$Width
    )

    if (-not $Width) { $Width = [Math]::Min((Get-NSPConsoleWidth), 100) }
    $rule = '=' * ($Width - 1)
    Write-NSPConsoleLine $rule -Role Heading
    $left = "  $Title"
    if ($Subtitle) {
        $gap = [Math]::Max(2, $Width - 1 - $left.Length - $Subtitle.Length - 2)
        Write-NSPConsoleSegment -Segment @(@($left, 'Heading'), (' ' * $gap), @($Subtitle, 'Strong'))
    } else {
        Write-NSPConsoleLine $left -Role Heading
    }
    Write-NSPConsoleLine $rule -Role Heading
}
