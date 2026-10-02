function Test-NSPBackSignal {
    <#
    .SYNOPSIS
        True when a prompt result is the back signal returned by Read-NSPNonEmpty or
        Read-NSPOptional with -AllowBack.
    .DESCRIPTION
        The signal is a private sentinel string, so a real answer can never be mistaken for it.
    .EXAMPLE
        $value = Read-NSPNonEmpty -Prompt 'Name' -AllowBack
        if (Test-NSPBackSignal $value) { $step-- ; continue }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Position = 0)][AllowNull()][AllowEmptyString()][object]$Value)

    return ($Value -is [string]) -and ($Value -ceq $script:NSPBackSignal)
}
