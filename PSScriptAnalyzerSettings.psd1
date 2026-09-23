@{
    IncludeDefaultRules = $true
    Severity = @('Error', 'Warning')
    ExcludeRules = @(
        # Interactive host output is the purpose of this module.
        'PSAvoidUsingWriteHost'

        # Maximizing an interactive window is best-effort presentation, not a
        # durable state change that should prompt with ShouldProcess.
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
