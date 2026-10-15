@{
    RootModule = 'NSP.Console.psm1'
    ModuleVersion = '0.1.5'
    GUID = '49cc39d3-fc4f-44a3-ac3e-e815a99309d6'
    Author = 'Network Systems Plus'
    CompanyName = 'Network Systems Plus'
    Copyright = '(c) 2026 Network Systems Plus. All rights reserved.'
    Description = 'Console presentation, prompts, layout, and best-effort window control for PowerShell operator tools.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Write-NSPConsoleLine'
        'Read-NSPChoice'
        'Read-NSPConfirm'
        'Get-NSPConsoleColumnLayout'
        'Set-NSPConsoleMaximized'
        'Read-NSPMenu'
        'Write-NSPConsoleHeader'
        'Write-NSPConsoleRule'
        'Write-NSPConsoleSegment'
        'Get-NSPConsoleWidth'
        'Clear-NSPConsole'
        'Read-NSPNonEmpty'
        'Read-NSPOptional'
        'Test-NSPBackSignal'
        'Read-NSPFilePath'
        'Read-NSPFolderPath'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Console', 'Prompt', 'PowerShell', 'Windows')
            ProjectUri = 'https://github.com/ITGuyFromIA2/NSP-Console'
            LicenseUri = 'https://github.com/ITGuyFromIA2/NSP-Console/blob/main/LICENSE'
            ReleaseNotes = '0.1.5: Read-NSPFolderPath - a folder prompt with a Windows folder picker, optional default and -Create.'
        }
    }
}
