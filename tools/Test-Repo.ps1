$ErrorActionPreference = 'Stop'
# Publishing -WhatIf must not turn the analyzer itself into a preview.
$WhatIfPreference = $false
$repoRoot = Split-Path -Parent $PSScriptRoot

# Public-source gate. Report locations only, never the matched line or value.
$publicFiles = @(
    Get-ChildItem -Path (Join-Path $repoRoot 'Public') -Filter '*.ps1' -File
    Get-Item (Join-Path $repoRoot 'README.md')
    Get-Item (Join-Path $repoRoot 'NSP.Console.psd1')
)
$privateMarker = '(?i)C:\\GitRepo\\|\\\\[a-z0-9._-]+\\|[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}'
foreach ($file in $publicFiles) {
    $hits = @(Select-String -LiteralPath $file.FullName -Pattern $privateMarker)
    if ($hits.Count) {
        $locations = ($hits | ForEach-Object { "$($file.Name):$($_.LineNumber)" }) -join ', '
        throw "Review possible private reference at $locations."
    }
}

foreach ($file in Get-ChildItem -Path $repoRoot -Recurse -File | Where-Object Extension -In '.ps1', '.psm1') {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count) { throw "PowerShell parser errors in $($file.FullName): $($errors[0].Message)" }
}

foreach ($exe in 'powershell.exe', 'pwsh.exe') {
    & $exe -NoProfile -File (Join-Path $repoRoot 'Tests\Smoke.ps1')
    if ($LASTEXITCODE -ne 0) { throw "$exe smoke checks failed." }
}

$analyzer = Get-Module -ListAvailable PSScriptAnalyzer | Select-Object -First 1
if ($analyzer) {
    Import-Module $analyzer.Path -Force
    $findings = @(Invoke-ScriptAnalyzer -Path $repoRoot -Recurse -Settings (Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'))
    if ($findings.Count) {
        $findings | Format-Table RuleName, Severity, ScriptName, Line, Message -AutoSize
        throw 'PSScriptAnalyzer reported findings.'
    }
} else {
    Write-Warning 'PSScriptAnalyzer is not installed; parser and behavior checks still ran.'
}

'NSP.Console repository checks passed.'
