@{
    description = 'Bootstrap pwsh settings'
    dependsOn = @(
        'pwsh-profiles'
        'pwsh-scripts'
        'slab-utils'
    )
}