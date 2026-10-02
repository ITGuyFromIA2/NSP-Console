function Read-NSPNonEmpty {
    <#
    .SYNOPSIS
        Reads a required value, prompting again on a blank answer. A blank answer keeps
        -CurrentValue when one is supplied.
    .DESCRIPTION
        -AllowBack lets a literal B or Back return the back signal (see Test-NSPBackSignal) instead
        of a value. Pass it only when the caller can step back to a previous prompt.
        -Answer supports noninteractive callers and tests; a blank -Answer with no -CurrentValue
        throws instead of looping.
    .EXAMPLE
        $name = Read-NSPNonEmpty -Prompt 'Group name' -CurrentValue $saved.GroupName
    .EXAMPLE
        $ou = Read-NSPNonEmpty -Prompt 'Target OU' -AllowBack
        if (Test-NSPBackSignal $ou) { return }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [AllowEmptyString()][string]$CurrentValue,
        [switch]$AllowBack,
        [AllowEmptyString()][string]$Answer
    )

    $hasCurrent = -not [string]::IsNullOrWhiteSpace($CurrentValue)
    $hint = if ($hasCurrent) { " (blank to keep '$CurrentValue')" } else { '' }
    $backHint = if ($AllowBack) { '  [B = back]' } else { '' }
    $provided = $PSBoundParameters.ContainsKey('Answer')

    while ($true) {
        $response = if ($provided) { $Answer } else { Read-Host ($Prompt + $hint + $backHint) }
        if ($AllowBack -and $response -match '^(?i)b(ack)?$') { return $script:NSPBackSignal }
        if ([string]::IsNullOrWhiteSpace($response)) {
            if ($hasCurrent) { return $CurrentValue }
            if ($provided) { throw 'A value is required.' }
            Write-NSPConsoleLine -Message '  A value is required.' -Role Warning
            continue
        }
        return $response.Trim()
    }
}
