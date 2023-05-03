targetScope = 'subscription'
param AzTenantID string = '2522b752-1926-4ccb-89a4-c465b37367f8'
param artifactsLocation string = 'https://bicepconfig.blob.core.windows.net/bicep'
param AVDResourceGroup string = 'ACME-AVD-RG'
param workspaceLocation string = 'eastus'

@description('Boolean used to determine if Monitoring agent is needed')
param monitoringAgent bool = false

@description('Whether to use emphemeral disks for VMs')
param ephemeral bool = true

@description('Declares whether Azure AD joined or not')
param AADJoin bool = false

@description('Determines if Session Hosts are auto enrolled in Intune')
param intune bool = false

@description('Expiration time for the HostPool registration token. This must be up to 30 days from todays date.')
param tokenExpirationTime string = '30'

@description('Domain that AVD Session Hosts will be joined to.')
param domain string = 'biceptest.local'

@description('If true Host Pool, App Group and Workspace will be created. Default is to join Session Hosts to existing AVD environment')
param newBuild bool = true
param administratorAccountUserName string = 'karan@techplustalent.com'

@secure()
param administratorAccountPassword string

@allowed([
  'Personal'
  'Pooled'
])
param hostPoolType string = 'Pooled'
param hostPoolName string = 'ACME-AZE-HP'

@allowed([
  'Automatic'
  'Direct'
])
param personalDesktopAssignmentType string = 'Direct'
param maxSessionLimit int = 12

@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadBalancerType string = 'BreadthFirst'

@description('Custom RDP properties to be applied to the AVD Host Pool.')
param customRdpProperty string = 'audiocapturemode:i:1;camerastoredirect:s:*;audiomode:i:0;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:0;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2;devicestoredirect:s:*'

@description('Friendly Name of the Host Pool, this is visible via the AVD client')
param hostPoolFriendlyName string = 'ACME-AZE-HP'

@description('Name of the AVD Workspace to used for this deployment')
param workspaceName string = 'ACME-AZE-WN'
param appGroupFriendlyName string = 'ACME-AZE-AG'

@description('List of application group resource IDs to be added to Workspace. MUST add existing ones!')
param applicationGroupReferences string
param desktopName string = 'ACME-AVD'

@description('CSV list of default users to assign to AVD Application Group.')
param defaultUsers string = 'karan@techplustalent.com'

@description('Application ID for Service Principal. Used for DSC scripts.')
param appID string = 'e88b896d-bddf-44b8-9a86-833a6b72c52f'

@description('Application Secret for Service Principal.')
@secure()
param appSecret string
param vmResourceGroup string = 'AADDS-RG'
param vmLocation string = 'East US'
param vmSize string = 'Standard_D2ds_v5'
param numberOfInstances int = 2
param currentInstances int = 0
param vmPrefix string = 'ACME-AVD'

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string = 'Premium_LRS'
param existingVNETResourceGroup string = 'AADDS-RG'

@description('Name of the VNET that the AVD Session Hosts will be connected to.')
param existingVNETName string = 'aadds-vnet'

@description('The name of the relevant VNET Subnet that is to be used for deployment.')
param existingSubnetName string = 'aadds-subnet'

@description('Subscription containing the Shared Image Gallery')
param sharedImageGallerySubscription string = 'f6ca4428-f4e1-4a58-85c4-b01ac9d03819'

@description('Resource Group containing the Shared Image Gallery.')
param sharedImageGalleryResourceGroup string = 'AADDS-RG'

@description('Name of the existing Shared Image Gallery to be used for image.')
param sharedImageGalleryName string = 'SIG'

@description('Name of the Shared Image Gallery Definition being used for deployment. I.e: AVDGolden')
param sharedImageGalleryDefinitionname string = 'avdwin10ms'

@description('Version name for image to be deployed as. I.e: 1.0.0')
param sharedImageGalleryVersionName string = '1.0.0'

//Used for Monitoring Module
@description('Subscription that Log Analytics Workspace is located in.')
param logworkspaceSub string = 'f6ca4428-f4e1-4a58-85c4-b01ac9d03819'
@description('Resource Group that Log Analytics Workspace is located in.')
param logworkspaceResourceGroup string = 'DefaultResourceGroup-EUS'
@description('Name of Log Analytics Workspace for AVD to be joined to.')
param logworkspaceName string = 'DefaultWorkspace-f6ca4428-f4e1-4a58-85c4-b01ac9d03819-EUS'

//Used in VMswitLA module
@description('Log Analytics Workspace ID')
param workspaceID string = '47a50f48-357b-4568-92c6-b0b09678cbc2'
@description('Log Analytics Workspace Key')
param workspaceKey string = 'NRdpI9GkY8bNKfb48d041XU3Bq3rZIlEzAtC/KaM2SVbHs8y6r5+xDoQf1kh1WB7LWXG48MV5nGGxtqQVRNdFg=='

module resourceGroupDeploy './modules/resourceGroup.bicep' = {
  name: 'backPlane'
  params: {
    AVDResourceGroup: AVDResourceGroup
    AVDlocation: workspaceLocation
    vmResourceGroup: vmResourceGroup
    VMlocation: vmLocation
  }
}

module backPlane './modules/backPlane.bicep' = {
  name: 'backPlane'
  scope: resourceGroup(AVDResourceGroup)
  params: {
    location: workspaceLocation
    workspaceLocation: workspaceLocation
    logworkspaceSub: logworkspaceSub
    logworkspaceResourceGroup: logworkspaceResourceGroup
    logworkspaceName: logworkspaceName
    hostPoolName: hostPoolName
    hostPoolFriendlyName: hostPoolFriendlyName
    hostPoolType: hostPoolType
    appGroupFriendlyName: appGroupFriendlyName
    applicationGroupReferences: applicationGroupReferences
    loadBalancerType: loadBalancerType
    workspaceName: workspaceName
    personalDesktopAssignmentType: personalDesktopAssignmentType
    customRdpProperty: customRdpProperty
    tokenExpirationTime: tokenExpirationTime
    maxSessionLimit: maxSessionLimit
    newBuild: newBuild
  }
  dependsOn: [
    resourceGroupDeploy
  ]
}


module VMswithLA './modules/VMswithLA.bicep' = {
  name: '${sharedImageGalleryVersionName}-VMswithLA'
  scope: resourceGroup(vmResourceGroup)
  params: {
    AzTenantID: AzTenantID
    location: vmLocation
    administratorAccountUserName: administratorAccountUserName
    administratorAccountPassword: '^57Som*#4uIac3'
    artifactsLocation: artifactsLocation
    vmDiskType: vmDiskType
    vmPrefix: vmPrefix
    vmSize: vmSize
    currentInstances: currentInstances
    AVDnumberOfInstances: numberOfInstances
    existingVNETResourceGroup: existingVNETResourceGroup
    existingVNETName: existingVNETName
    existingSubnetName: existingSubnetName
    sharedImageGallerySubscription: sharedImageGallerySubscription
    sharedImageGalleryResourceGroup: sharedImageGalleryResourceGroup
    sharedImageGalleryName: sharedImageGalleryName
    sharedImageGalleryDefinitionname: sharedImageGalleryDefinitionname
    sharedImageGalleryVersionName: sharedImageGalleryVersionName
    hostPoolName: hostPoolName
    domainToJoin: domain
    appGroupName: reference(extensionResourceId('/subscriptions/${subscription().subscriptionId}/resourceGroups/${AVDResourceGroup}', 'Microsoft.Resources/deployments', 'backPlane'), '2019-10-01').outputs.appGroupName.value
    appID: appID
    appSecret: 'TVo8Q~DAXcGCrpjKVmd9~JMmsUmg11zuxfOzMb4-'
    defaultUsers: defaultUsers
    desktopName: desktopName
    resourceGroupName: AVDResourceGroup
    workspaceID: workspaceID
    workspaceKey: workspaceKey
    monitoringAgent: monitoringAgent
    ephemeral: ephemeral
    AADJoin: AADJoin
    intune: intune
  }
  dependsOn: [
    backPlane
  ]
}
