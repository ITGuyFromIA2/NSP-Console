function Clear-NSPConsole {
    <#
    .SYNOPSIS
        Clears the screen before a new menu or screen; does nothing where output is redirected.
    .DESCRIPTION
        A redirected or captured host (a transcript-only run, a test, a pipeline) keeps its
        scrollback, so nothing an operator or a log needs is lost.
    .EXAMPLE
        Clear-NSPConsole
    #>
    [CmdletBinding()]
    param()

    try {
        if ([Console]::IsOutputRedirected) { return }
        Clear-Host
    } catch {
        Write-Verbose "The screen was not cleared: $_"
    }
}
