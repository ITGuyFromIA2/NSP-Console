function Read-NSPMenu {
    <#
    .SYNOPSIS
        Displays a menu of numbered and lettered entries, with optional help lines, and returns the chosen entry's value.
    .DESCRIPTION
        Each choice needs Label and Value. An optional Key (a letter or word, such as N) is typed to
        pick it; choices without a Key are numbered in order. An optional Help line is shown
        under the label, muted. An optional Section starts a titled group before that choice.
        Keys and numbers are shown in the Key color. Keys match case-insensitively.

        -Inline lists entries across the line instead of one per line, wrapping at the console
        width, for a short menu under a dashboard. Help lines are not shown inline.

        The cancel key returns $null. Invalid input retries. -Answer supplies the typed answer
        for noninteractive callers and tests; an invalid -Answer throws.
    .EXAMPLE
        Read-NSPMenu -Prompt 'Choose' -Choices @(
            [pscustomobject]@{ Label = 'Add travel'; Value = 'Travel'; Help = 'Allow sign-ins from a country for a while.' }
            [pscustomobject]@{ Key = 'N'; Label = 'New tenant'; Value = 'New' }
        )
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Choices,
        [string]$Prompt = 'Select an option',
        [string]$CancelKey = 'Q',
        [string]$CancelLabel = 'Cancel',
        [switch]$Inline,
        [string]$Answer
    )

    function Get-Field {
        param($Object, [string]$Name)
        if ($Object -is [System.Collections.IDictionary]) { return $Object[$Name] }
        $property = $Object.PSObject.Properties[$Name]
        if ($property) { $property.Value } else { $null }
    }

    if ($Choices.Count -eq 0) { throw 'At least one choice is required.' }
    $entries = [System.Collections.Generic.List[object]]::new()
    $number = 0
    foreach ($choice in $Choices) {
        if ($null -eq $choice -or $null -eq (Get-Field $choice 'Label')) { throw 'Each choice requires Label and Value properties.' }
        $key = [string](Get-Field $choice 'Key')
        if (-not $key) { $number++; $key = [string]$number }
        if ($key -ieq $CancelKey) { throw "Key '$key' is the cancel key." }
        if (@($entries | Where-Object { $_.Key -ieq $key }).Count) { throw "Key '$key' is used twice." }
        $entries.Add([pscustomobject]@{
                Key = $key; Label = [string](Get-Field $choice 'Label'); Value = Get-Field $choice 'Value'
                Help = [string](Get-Field $choice 'Help'); Section = [string](Get-Field $choice 'Section')
            })
    }

    $provided = $PSBoundParameters.ContainsKey('Answer')
    if (-not $provided) {
        if ($Inline) {
            $width = Get-NSPConsoleWidth
            # $column is the current line's length; 0 means nothing is on it yet.
            $column = 0
            foreach ($entry in @($entries) + [pscustomobject]@{ Key = $CancelKey; Label = $CancelLabel; Section = $null }) {
                if ($entry.Section) {
                    if ($column) { Write-Host ''; $column = 0 }
                    Write-NSPConsoleLine "  $($entry.Section)" -Role Heading
                }
                $cell = "$($entry.Key) $($entry.Label)   "
                if ($column -and ($column + $cell.Length) -ge $width) { Write-Host ''; $column = 0 }
                if (-not $column) { Write-Host '  ' -NoNewline; $column = 2 }
                Write-NSPConsoleLine $entry.Key -Role Key -NoNewline
                Write-Host " $($entry.Label)   " -NoNewline
                $column += $cell.Length
            }
            Write-Host ''
        } else {
            $keyWidth = (@($entries | ForEach-Object { $_.Key.Length }) + $CancelKey.Length | Measure-Object -Maximum).Maximum
            foreach ($entry in $entries) {
                if ($entry.Section) { Write-NSPConsoleRule -Title $entry.Section -Role Muted }
                Write-NSPConsoleLine ('  {0}. ' -f $entry.Key.PadLeft($keyWidth)) -Role Key -NoNewline
                Write-Host $entry.Label
                if ($entry.Help) { Write-NSPConsoleLine ('  {0}  {1}' -f (' ' * $keyWidth), $entry.Help) -Role Muted }
            }
            Write-NSPConsoleLine ('  {0}. ' -f $CancelKey.PadLeft($keyWidth)) -Role Key -NoNewline
            Write-NSPConsoleLine $CancelLabel -Role Muted
        }
    }

    while ($true) {
        $response = if ($provided) { $Answer } else { Read-Host $Prompt }
        if ($null -eq $response) { return $null }
        $response = $response.Trim()
        if ($response -ieq $CancelKey) { return $null }
        $match = @($entries | Where-Object { $_.Key -ieq $response })
        if ($match.Count) { return $match[0].Value }
        if ($provided) { throw "'$Answer' is not one of the menu's keys." }
        Write-NSPConsoleLine -Message 'Invalid selection. Type a listed number or letter.' -Role Warning
    }
}
