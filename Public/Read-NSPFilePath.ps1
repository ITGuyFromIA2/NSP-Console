function Read-NSPFilePath {
    <#
    .SYNOPSIS
        Asks for an existing file: Enter opens a Windows file picker, or the path can be typed or pasted.
    .DESCRIPTION
        Returns the full path of an existing file. Surrounding quotes are removed, so a path copied
        with Explorer's "Copy as path" pastes as-is. A missing path is reported and asked again.

        Dropping a file onto a console window types its path, but Windows blocks drops from Explorer
        onto an ELEVATED console, which is why the picker is offered. The picker runs on its own STA
        thread (PowerShell 7 consoles are MTA) and is skipped where there is no desktop - a remote
        session, Server Core, or NSP_NO_FILEDIALOG=1 - leaving the typed path.

        -AllowBack lets B or Back return the back signal (see Test-NSPBackSignal). -Answer supports
        noninteractive callers and tests: it is used as the typed path and a missing file throws.
    .EXAMPLE
        $csr = Read-NSPFilePath -Prompt 'FortiGate CSR' -Filter 'Certificate requests (*.csr;*.req;*.pem)|*.csr;*.req;*.pem|All files (*.*)|*.*'
    .EXAMPLE
        $file = Read-NSPFilePath -Prompt 'Backup file' -InitialDirectory $env:USERPROFILE -AllowBack
        if (Test-NSPBackSignal $file) { return }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Filter = 'All files (*.*)|*.*',
        [string]$InitialDirectory,
        [switch]$AllowBack,
        [AllowEmptyString()][string]$Answer
    )

    $canBrowse = $env:NSP_NO_FILEDIALOG -ne '1' -and [Environment]::UserInteractive -and $Host.Name -ne 'ServerRemoteHost'
    $showDialog = {
        $dialog = {
            param($Title, $Filter, $InitialDirectory)
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
            $owner = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true; ShowInTaskbar = $false }
            $picker = New-Object System.Windows.Forms.OpenFileDialog -Property @{ Title = $Title; Filter = $Filter; CheckFileExists = $true }
            if ($InitialDirectory -and (Test-Path -LiteralPath $InitialDirectory -PathType Container)) { $picker.InitialDirectory = $InitialDirectory }
            try { if ($picker.ShowDialog($owner) -eq [System.Windows.Forms.DialogResult]::OK) { $picker.FileName } }
            finally { $picker.Dispose(); $owner.Dispose() }
        }
        try {
            if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -eq 'STA') {
                return & $dialog $Prompt $Filter $InitialDirectory
            }
            $runspace = [runspacefactory]::CreateRunspace()
            $runspace.ApartmentState = 'STA'
            $runspace.Open()
            $ps = [powershell]::Create()
            $ps.Runspace = $runspace
            try { return @($ps.AddScript($dialog.ToString()).AddArgument($Prompt).AddArgument($Filter).AddArgument($InitialDirectory).Invoke()) | Select-Object -First 1 }
            finally { $ps.Dispose(); $runspace.Dispose() }
        } catch {
            Write-Verbose "File picker unavailable: $($_.Exception.Message)"
            return $null
        }
    }

    $backHint = if ($AllowBack) { '  [B = back]' } else { '' }
    $browseHint = if ($canBrowse) { ' - Enter to browse, or paste a path' } else { ' - type or paste the path' }
    while ($true) {
        $response = if ($PSBoundParameters.ContainsKey('Answer')) { $Answer } else { Read-Host ($Prompt + $browseHint + $backHint) }
        if ($AllowBack -and $response -match '^(?i)b(ack)?$') { return $script:NSPBackSignal }
        $path = "$response".Trim().Trim('"', "'").Trim()

        if (-not $path) {
            if ($PSBoundParameters.ContainsKey('Answer')) { throw "$Prompt`: no file given." }
            if (-not $canBrowse) { Write-Host '  Type or paste the full path.' -ForegroundColor Yellow; continue }
            $path = & $showDialog
            if (-not $path) { Write-Host '  No file chosen - pick one, or type or paste the path.' -ForegroundColor Yellow; continue }
        }

        if (Test-Path -LiteralPath $path -PathType Leaf) { return (Resolve-Path -LiteralPath $path).ProviderPath }
        if ($PSBoundParameters.ContainsKey('Answer')) { throw "$Prompt`: file not found: $path" }
        Write-Host "  File not found: $path" -ForegroundColor Yellow
    }
}
