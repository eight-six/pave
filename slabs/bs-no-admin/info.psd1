@{
    description = 'Bootstrap a Windows dev machine without admin rights'
    dependsOn = @('slab-utils', 'user-apps', 'user-apps-winget')
}