



switch ($MyInvocation.InvocationName) {
    '.' { "Was dot sourced" }
    '&' { "Was invoked with the call operator" }
    Default {
        "Was invoked by name"
    }
}