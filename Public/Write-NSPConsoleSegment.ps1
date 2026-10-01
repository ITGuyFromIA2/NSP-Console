function Write-NSPConsoleSegment {
    <#
    .SYNOPSIS
        Writes one line made of differently colored pieces, such as a label and its status.
    .DESCRIPTION
        Each segment is a string (Normal), a two-item array of text and role, or an object with
        Text and Role (or Color) properties. Roles are those of Write-NSPConsoleLine. -Width pads
        a segment to a fixed number of characters so columns line up, and shortens a longer
        one with '..'.
    .EXAMPLE
        Write-NSPConsoleSegment -Segment @(@('  Session  ', 'Muted'), @('signed in', 'Success'))
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Segment,
        [switch]$NoNewline
    )

    foreach ($piece in $Segment) {
        if ($null -eq $piece) { continue }
        $text = $null
        $role = 'Normal'
        $color = $null
        $width = 0
        if ($piece -is [string]) {
            $text = $piece
        } elseif ($piece -is [System.Collections.IList]) {
            $text = [string]$piece[0]
            if ($piece.Count -gt 1 -and $piece[1]) { $role = [string]$piece[1] }
            if ($piece.Count -gt 2 -and $piece[2]) { $width = [int]$piece[2] }
        } else {
            $values = if ($piece -is [System.Collections.IDictionary]) { $piece } else {
                $map = @{}
                foreach ($property in $piece.PSObject.Properties) { $map[$property.Name] = $property.Value }
                $map
            }
            $text = [string]$values['Text']
            if ($values['Role']) { $role = [string]$values['Role'] }
            if ($values['Color']) { $color = [ConsoleColor]$values['Color'] }
            if ($values['Width']) { $width = [int]$values['Width'] }
        }
        if ($width -gt 0) {
            if ($text.Length -gt $width) { $text = $text.Substring(0, [Math]::Max(0, $width - 2)) + '..' }
            $text = $text.PadRight($width)
        }
        $arguments = @{ Message = $text; Role = $role; NoNewline = $true }
        if ($null -ne $color) { $arguments.ForegroundColor = $color }
        Write-NSPConsoleLine @arguments
    }
    if (-not $NoNewline) { Write-Host '' }
}
