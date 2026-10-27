@{
    # The default Error and Warning rules apply, except for two that don't fit this repo:
    # - PSAvoidUsingWriteHost: the setup scripts and the tests print coloured, user-facing console output.
    # - PSReviewUnusedParameter: it can't see a parameter that a nested function reads (false positives).
    Severity     = @('Error', 'Warning')
    ExcludeRules = @('PSAvoidUsingWriteHost', 'PSReviewUnusedParameter')
}
