function Read-NSPChoice {
    <#
    .SYNOPSIS
        Displays numbered choices and returns the selected item's stable value.
    .DESCRIPTION
        Accepts objects with Label and Value properties. Values can be strings or
        objects. Invalid interactive input retries by default; ReturnNull preserves
        tools whose caller returns to an outer menu on invalid input. Cancel returns $null.
        -Selection supplies a number for noninteractive callers. The caller owns
        the action taken after selection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Choices,
        [string]$Prompt = 'Select an option',
        [string]$CancelKey = 'Q',
        [ValidateSet('Retry', 'ReturnNull')][string]$InvalidSelectionAction = 'Retry',
        [int]$Selection
    )

    if ($Choices.Count -eq 0) { throw 'At least one choice is required.' }
    foreach ($choice in $Choices) {
        if ($null -eq $choice -or $null -eq $choice.PSObject.Properties['Label'] -or
            $null -eq $choice.PSObject.Properties['Value']) {
            throw 'Each choice requires Label and Value properties.'
        }
    }

    if ($PSBoundParameters.ContainsKey('Selection')) {
        if ($Selection -lt 1 -or $Selection -gt $Choices.Count) {
            throw "Selection must be between 1 and $($Choices.Count)."
        }
        return $Choices[$Selection - 1].Value
    }

    for ($index = 0; $index -lt $Choices.Count; $index++) {
        Write-Host ('  {0}. {1}' -f ($index + 1), $Choices[$index].Label)
    }
    Write-NSPConsoleLine -Message "  $CancelKey. Cancel" -Role Muted

    while ($true) {
        $answer = Read-Host $Prompt
        if ($null -eq $answer) { return $null }
        $answer = $answer.Trim()
        if ($answer -ieq $CancelKey) { return $null }
        $number = 0
        if ([int]::TryParse($answer, [ref]$number) -and
            $number -ge 1 -and $number -le $Choices.Count) {
            return $Choices[$number - 1].Value
        }
        if ($InvalidSelectionAction -eq 'ReturnNull') {
            Write-NSPConsoleLine -Message 'Invalid selection.' -Role Warning
            return $null
        }
        Write-NSPConsoleLine -Message 'Invalid selection. Choose a listed number or cancel.' -Role Warning
    }
}
