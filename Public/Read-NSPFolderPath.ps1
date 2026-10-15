function Read-NSPFolderPath {
    <#
    .SYNOPSIS
        Asks for a folder: Enter opens a Windows folder picker, or the path can be typed or pasted.
    .DESCRIPTION
        Returns the full path of a folder. Surrounding quotes are removed, so a path copied with
        Explorer's "Copy as path" pastes as-is. A missing folder is reported and asked again - or,
        with -Create, offered to be created (created without asking when -Answer is used).

        The picker is the folder counterpart of Read-NSPFilePath's: Windows blocks dropping a folder
        onto an ELEVATED console, so it is how a tech "drags" one in. It runs on its own STA thread
        (PowerShell 7 consoles are MTA) and is skipped where there is no desktop - a remote session,
        Server Core, or NSP_NO_FILEDIALOG=1 - leaving the typed path. Blank with -Default returns
        the default instead of opening the picker.

        -AllowBack lets B or Back return the back signal (see Test-NSPBackSignal). -Answer supports
        noninteractive callers and tests: it is used as the typed path, and a missing folder throws
        (unless -Create).
    .EXAMPLE
        $dir = Read-NSPFolderPath -Prompt 'Capture folder' -Default 'D:\Captures' -Create
    .EXAMPLE
        $src = Read-NSPFolderPath -Prompt 'Source folder' -InitialDirectory $env:USERPROFILE -AllowBack
        if (Test-NSPBackSignal $src) { return }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Default,
        [string]$InitialDirectory,
        [switch]$Create,
        [switch]$AllowBack,
        [AllowEmptyString()][string]$Answer
    )

    $provided = $PSBoundParameters.ContainsKey('Answer')
    $canBrowse = $env:NSP_NO_FILEDIALOG -ne '1' -and [Environment]::UserInteractive -and $Host.Name -ne 'ServerRemoteHost'
    if (-not $InitialDirectory -and $Default) { $InitialDirectory = $Default }
    $showDialog = {
        $dialog = {
            param($Title, $InitialDirectory)
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
            $owner = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true; ShowInTaskbar = $false }
            $picker = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{ Description = $Title; ShowNewFolderButton = $true }
            # .NET Core 3+ (PowerShell 7) shows the modern dialog and can use the description as its title.
            if ($picker.PSObject.Properties['UseDescriptionForTitle']) { $picker.UseDescriptionForTitle = $true }
            if ($InitialDirectory -and (Test-Path -LiteralPath $InitialDirectory -PathType Container)) { $picker.SelectedPath = $InitialDirectory }
            try { if ($picker.ShowDialog($owner) -eq [System.Windows.Forms.DialogResult]::OK) { $picker.SelectedPath } }
            finally { $picker.Dispose(); $owner.Dispose() }
        }
        try {
            if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -eq 'STA') {
                return & $dialog $Prompt $InitialDirectory
            }
            $runspace = [runspacefactory]::CreateRunspace()
            $runspace.ApartmentState = 'STA'
            $runspace.Open()
            $ps = [powershell]::Create()
            $ps.Runspace = $runspace
            try { return @($ps.AddScript($dialog.ToString()).AddArgument($Prompt).AddArgument($InitialDirectory).Invoke()) | Select-Object -First 1 }
            finally { $ps.Dispose(); $runspace.Dispose() }
        } catch {
            Write-Verbose "Folder picker unavailable: $($_.Exception.Message)"
            return $null
        }
    }

    $backHint = if ($AllowBack) { '  [B = back]' } else { '' }
    $defaultHint = if ($Default) { " (blank for '$Default')" } else { '' }
    $browseHint = if ($Default) { $(if ($canBrowse) { ', ? to browse, or paste a path' } else { ', or type or paste a path' }) }
    elseif ($canBrowse) { ' - Enter to browse, or paste a path' } else { ' - type or paste the path' }
    while ($true) {
        $response = if ($provided) { $Answer } else { Read-Host ($Prompt + $defaultHint + $browseHint + $backHint) }
        if ($AllowBack -and $response -match '^(?i)b(ack)?$') { return $script:NSPBackSignal }
        $path = "$response".Trim().Trim('"', "'").Trim()

        if ($path -eq '?' -or (-not $path -and -not $Default)) {
            if ($provided) { throw "$Prompt`: no folder given." }
            if (-not $canBrowse) { Write-Host '  Type or paste the full path.' -ForegroundColor Yellow; continue }
            $path = & $showDialog
            if (-not $path) { Write-Host '  No folder chosen - pick one, or type or paste the path.' -ForegroundColor Yellow; continue }
        } elseif (-not $path) {
            $path = $Default
        }

        if (Test-Path -LiteralPath $path -PathType Container) { return (Resolve-Path -LiteralPath $path).ProviderPath }
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            if ($provided) { throw "$Prompt`: that is a file, not a folder: $path" }
            Write-Host "  That is a file, not a folder: $path" -ForegroundColor Yellow
            continue
        }
        if ($Create -and ($provided -or (Read-NSPConfirm -Prompt "  $path does not exist. Create it?" -DefaultYes))) {
            try {
                New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop | Out-Null
                return (Resolve-Path -LiteralPath $path).ProviderPath
            } catch {
                if ($provided) { throw "$Prompt`: could not create ${path}: $($_.Exception.Message)" }
                Write-Host "  Could not create ${path}: $($_.Exception.Message)" -ForegroundColor Yellow
                continue
            }
        }
        if ($provided) { throw "$Prompt`: folder not found: $path" }
        Write-Host "  Folder not found: $path" -ForegroundColor Yellow
    }
}
