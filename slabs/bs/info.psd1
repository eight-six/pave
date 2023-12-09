@{
    description = 'Bootstrap a Windows development machine'
    dependsOn = @(
        'bs-no-admin'
        'bs-pwsh'
        'bs-winget'
        'slab-utils'
    )

}