function Read-NSPOptional {
    <#
    .SYNOPSIS
        Reads a value that may be blank (skip or default) - a single prompt with no retry loop.
    .DESCRIPTION
        The back-aware equivalent of a bare Read-Host. -AllowBack lets a literal B or Back return
        the back signal (see Test-NSPBackSignal). Blank returns -Default (an empty string when no
        default is given). -Answer supports noninteractive callers and tests.
    .EXAMPLE
        $filter = Read-NSPOptional -Prompt 'Name filter (blank for all)'
    .EXAMPLE
        $port = Read-NSPOptional -Prompt 'Port' -Default '1812' -AllowBack
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [AllowEmptyString()][string]$Default = '',
        [switch]$AllowBack,
        [AllowEmptyString()][string]$Answer
    )

    $hint = if ($Default) { " (blank for '$Default')" } else { '' }
    $backHint = if ($AllowBack) { '  [B = back]' } else { '' }
    $response = if ($PSBoundParameters.ContainsKey('Answer')) { $Answer } else { Read-Host ($Prompt + $hint + $backHint) }
    if ($AllowBack -and $response -match '^(?i)b(ack)?$') { return $script:NSPBackSignal }
    if ([string]::IsNullOrWhiteSpace($response)) { return $Default }
    return $response.Trim()
}
