function Write-NSPConsoleLine {
    <#
    .SYNOPSIS
        Writes one operator-facing line with a consistent color role.
    .DESCRIPTION
        Uses host colors available in Windows PowerShell 5.1 and PowerShell 7.
        The message carries its own meaning when color is unavailable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][AllowEmptyString()][string]$Message,
        [ValidateSet('Normal', 'Heading', 'Action', 'Success', 'Warning', 'Error', 'Muted')]
        [string]$Role = 'Normal',
        [ConsoleColor]$ForegroundColor,
        [switch]$NoNewline
    )

    $colors = @{
        Heading = 'Cyan'
        Action  = 'Cyan'
        Success = 'Green'
        Warning = 'Yellow'
        Error   = 'Red'
        Muted   = 'DarkGray'
    }
    $arguments = @{ Object = $Message; NoNewline = [bool]$NoNewline }
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        $arguments.ForegroundColor = $ForegroundColor
    } elseif ($Role -ne 'Normal') {
        $arguments.ForegroundColor = $colors[$Role]
    }
    Write-Host @arguments
}
