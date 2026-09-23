function Read-NSPConfirm {
    <#
    .SYNOPSIS
        Reads a yes/no answer with an explicit default and retry behavior.
    .DESCRIPTION
        -Answer supports noninteractive callers and tests. A blank answer uses
        DefaultYes when specified.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [switch]$DefaultYes,
        [string]$Answer
    )

    $suffix = if ($DefaultYes) { ' [Y/n]' } else { ' [y/N]' }
    $provided = $PSBoundParameters.ContainsKey('Answer')
    while ($true) {
        $response = if ($provided) { $Answer } else { Read-Host ($Prompt + $suffix) }
        if ($null -eq $response) {
            if ($provided) { throw 'Answer cannot be null.' }
            return [bool]$DefaultYes
        }
        $response = $response.Trim()
        if ($response -eq '') { return [bool]$DefaultYes }
        if ($response -imatch '^y(es)?$') { return $true }
        if ($response -imatch '^n(o)?$') { return $false }
        if ($provided) { throw "Answer must be yes or no; received '$Answer'." }
        Write-NSPConsoleLine -Message 'Please answer y or n.' -Role Warning
    }
}
