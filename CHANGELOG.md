# Changelog

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
