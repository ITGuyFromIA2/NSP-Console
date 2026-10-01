function Get-NSPConsoleWidth {
    <#
    .SYNOPSIS
        The console window's width in characters, or -Default where the host has no window.
    .EXAMPLE
        $width = Get-NSPConsoleWidth
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [ValidateRange(20, 1000)][int]$Default = 120
    )

    try {
        $width = $Host.UI.RawUI.WindowSize.Width
        if ($width -and $width -ge 20) { return [int]$width }
    } catch {
        Write-Verbose "No console window width: $_"
    }
    $Default
}
