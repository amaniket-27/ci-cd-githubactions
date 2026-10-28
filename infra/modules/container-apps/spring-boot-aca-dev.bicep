targetScope = 'resourceGroup'

@description('Azure region for the resources.')
param location string = resourceGroup().location

@description('Log Analytics workspace name.')
param logAnalyticsName string

@description('Azure Container Apps environment name.')
param containerAppsEnvironmentName string

@description('Container App name.')
param containerAppName string

@description('Docker Hub image, including its tag.')
param containerImage string

@description('Port on which the Spring Boot application listens.')
@minValue(1)
@maxValue(65535)
param targetPort int = 8081

@description('Enable external HTTP ingress.')
param externalIngress bool = true

@description('Minimum number of replicas.')
@minValue(0)
param minReplicas int = 0

@description('Maximum number of replicas.')
@minValue(1)
param maxReplicas int = 2

@description('Container CPU allocation.')
@allowed([
  '0.25'
  '0.5'
  '0.75'
  '1'
])
param cpu string = '0.5'

@description('Container memory allocation.')
param memory string = '1Gi'

@description('Spring Boot application environment variables.')
param appEnvironmentVariables array = []

@description('Resource tags.')
param tags object = {
  environment:'dev'
}

// Log Analytics workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Container Apps managed environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppsEnvironmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Spring Boot Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id

    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: externalIngress
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
      }
    }

    template: {
      containers: [
        {
          name: 'spring-boot-app'
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: appEnvironmentVariables

        }
      ]

      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

// Deployment outputs
output containerAppName string = containerApp.name

output containerAppId string = containerApp.id

output containerAppsEnvironmentId string = containerAppsEnvironment.id

output logAnalyticsWorkspaceId string = logAnalytics.id

output applicationUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'