targetScope = 'subscription'

@description('Name of the resource group to create.')
@minLength(1)
param resourceGroupName string

@description('Azure region for the resource group.')
param location string = 'centralindia'

@description('Tags to apply to the resource group.')
param tags object = {
   Environment: 'Dev'
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
output resourceGroupLocation string = resourceGroup.location