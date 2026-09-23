function Set-NSPConsoleMaximized {
    <#
    .SYNOPSIS
        Maximizes the focused PowerShell console or terminal window when supported.
    .DESCRIPTION
        Uses the UI Automation WindowPattern, following the focused element's parents
        to the containing window. Call at interactive startup while this console has
        focus. This is best-effort: unsupported hosts and missing UI Automation
        assemblies leave the window as it is. No native API declarations are used.

        UI Automation reaches the visible terminal window by walking from its
        focused control to the containing Window. This avoids relying on a
        pseudoconsole handle or resizing character-cell buffers.
    #>
    try {
        Add-Type -AssemblyName UIAutomationClient -ErrorAction Stop
        Add-Type -AssemblyName UIAutomationTypes -ErrorAction Stop

        $focused = [System.Windows.Automation.AutomationElement]::FocusedElement
        if ($focused) {
            $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
            $current = $focused
            $windowElement = $null
            $hops = 0
            while ($current -and $hops -lt 15) {
                if ($current.Current.ControlType -eq [System.Windows.Automation.ControlType]::Window) {
                    $windowElement = $current
                    break
                }
                $current = $walker.GetParent($current)
                $hops++
            }
            if ($windowElement) {
                $patternObj = $null
                if ($windowElement.TryGetCurrentPattern([System.Windows.Automation.WindowPattern]::Pattern, [ref]$patternObj)) {
                    ([System.Windows.Automation.WindowPattern]$patternObj).SetWindowVisualState([System.Windows.Automation.WindowVisualState]::Maximized)
                }
            }
        }
    } catch {
        # A missing window or unsupported host must not interrupt the tool's menu.
        Write-Verbose "Set-NSPConsoleMaximized: $($_.Exception.Message)"
    }
}
