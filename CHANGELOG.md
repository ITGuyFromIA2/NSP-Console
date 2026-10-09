# Changelog

## 0.1.4

- Release routine: `tools\Publish-ToGallery.ps1` now runs `Publish-NSPModule` from NSP.RepoTools, the checks every NSP module shares (including a client-reference sweep of the Git history). No change to the module itself.

## 0.1.3

`Read-NSPFilePath` asks for an existing file: Enter opens a Windows file picker (on its own STA
thread, so it also works in PowerShell 7), or the path can be typed or pasted - the quotes from
Explorer's "Copy as path" are removed. Windows blocks dropping a file onto an elevated console, which
is why the picker is offered. There is no picker in a remote session, on Server Core, or with
`NSP_NO_FILEDIALOG=1`. `Set-NSPConsoleMaximized` is now an advanced function (common parameters such
as `-Verbose`), and the loader dot-sources files in name order.

## 0.1.2

Value prompts for wizard-style tools, folded from the IPSec toolkit's AD and CA managers:
`Read-NSPNonEmpty` (required value; blank retries, or keeps `-CurrentValue`), `Read-NSPOptional`
(single prompt that may be blank, with `-Default`), and `Test-NSPBackSignal`. Both prompts take
`-AllowBack`, so B or Back steps back to the previous prompt, and `-Answer` for noninteractive use.
Also includes the menu and header layout fixes made after 0.1.1: a blank line before each inline
section, and the header and rule follow the window up to 200 columns.

## 0.1.1

Dashboard-style screens, folded from the IPSec Master Orchestrator's console code:
`Read-NSPMenu` (numbered and lettered entries such as N for new, optional muted help lines and
section rules, or an inline layout under a dashboard), `Write-NSPConsoleHeader` (the `=====`
banner, with a right-aligned subtitle), `Write-NSPConsoleRule` (`-- Section ----`),
`Write-NSPConsoleSegment` (one line in several colors, with fixed-width cells),
`Get-NSPConsoleWidth`, and `Clear-NSPConsole` (skipped when output is redirected).
`Write-NSPConsoleLine` gains the Key (yellow), Accent (magenta), and Strong (white) roles, and
`Read-NSPChoice` shows its numbers in the Key color. Both set the lettered options (N, Q, ...) apart
from the numbered list with a blank line.

## 0.1.0

Initial public module: semantic console colors, numbered choices, yes/no prompts,
column layout calculations, and best-effort console maximization.
