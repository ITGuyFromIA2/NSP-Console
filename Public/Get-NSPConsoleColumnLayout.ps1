function Get-NSPConsoleColumnLayout {
    <#
    .SYNOPSIS
        Calculates a compact numbered-field layout for a given console width.
    .DESCRIPTION
        Performs layout math only; the caller owns its rows and colors.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateRange(40, 1000)][int]$ConsoleWidth,
        [Parameter(Mandatory)][ValidateRange(1, 200)][int]$MaxLabelLength
    )

    # Reserve room for the numbered prefix and at least 12 value characters,
    # even at the smallest supported console width.
    $available  = $ConsoleWidth - 3
    $labelWidth = [Math]::Min([Math]::Max($MaxLabelLength, 14), 30)
    $labelWidth = [Math]::Min($labelWidth, ($available - 18))
    $cellFixed  = $labelWidth + 6
    $gutter     = 3
    $minValue   = 18
    $maxValue   = 40

    $columns = 1
    for ($candidate = 4; $candidate -ge 1; $candidate--) {
        $perColumn = [Math]::Floor(($available - ($candidate - 1) * $gutter) / $candidate)
        if (($perColumn - $cellFixed) -ge $minValue) {
            $columns = $candidate
            break
        }
    }

    $valueWidth = [Math]::Floor(($available - ($columns - 1) * $gutter) / $columns) - $cellFixed
    if ($valueWidth -gt $maxValue) { $valueWidth = $maxValue }
    if ($valueWidth -lt 12) { $valueWidth = 12 }
    $columnWidth = $cellFixed + $valueWidth
    $ruleWidth = ($columns * $columnWidth) + (($columns - 1) * $gutter)
    if ($ruleWidth -gt ($ConsoleWidth - 3)) { $ruleWidth = $ConsoleWidth - 3 }

    [pscustomobject]@{
        LabelWidth  = $labelWidth
        ValueWidth  = $valueWidth
        Columns     = $columns
        Gutter      = $gutter
        ColumnWidth = $columnWidth
        RuleWidth   = $ruleWidth
    }
}
