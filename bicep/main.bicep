@description('Resources location')
param location string = resourceGroup().location

//----------- Storage Account Parameters ------------
@description('Function Storage Account name')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Function Storage Account SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageAccountSku string = 'Standard_LRS'

//----------- Application Insights Parameters ------------
@description('Application Insights name')
param applicationInsightsName string

//----------- Function App Parameters ------------
@description('Function App Plan name')
param planName string

@description('Function App Plan operating system')
@allowed([
  'Windows'
  'Linux'
])
param planOS string

@description('Function App name')
param functionAppName string

@description('Function App runtime')
@allowed([
  'dotnet'
  'node'
  'python'
  'java'
])
param functionAppRuntime string

//----------- Key Vault Parameters ------------
@description('Key Vault name')
param keyVaultName string

@description('Key Vault SKU')
@allowed([
  'standard'
  'premium'
])
param keyVaultSku string = 'standard'

@description('Database Connection String')
@secure()
param databaseConnectionString string


var buildNumber = uniqueString(resourceGroup().id)

//----------- Storage Account Deployment ------------
module storageAccountModule 'templates/StorageAccount.bicep' = {
  name: 'stvmdeploy-${buildNumber}'
  params: {
    name: storageAccountName
    sku: storageAccountSku
    location: location
  }
}

//----------- Application Insights Deployment ------------
module applicationInsightsModule 'templates/ApplicationInsights.bicep' = {
  name: 'appideploy-${buildNumber}'
  params: {
    name: applicationInsightsName
    location: location
  }
}

//----------- App Service Plan Deployment ------------
module appServicePlan 'templates/AppServicePlan.bicep' = {
  name: 'plandeploy-${buildNumber}'
  params: {
    name: planName
    location: location
    os: planOS
  }
}

//----------- Function App Deployment ------------
module functionAppModule 'templates/FunctionApp.bicep' = {
  name: 'funcdeploy-${buildNumber}'
  params: {
    name: functionAppName
    location: location
    planId: appServicePlan.outputs.planId
  }
  dependsOn: [
    storageAccountModule
    applicationInsightsModule
    appServicePlan
  ]
}

//----------- Key Vault Deployment ------------
module keyVaultModule 'templates/KeyVault.bicep' = {
  name: 'kvdeploy-${buildNumber}'
  params: {
    name: keyVaultName
    location: location
    sku: keyVaultSku
    funcTenantId: functionAppModule.outputs.tenantId
    funcPrincipalId: functionAppModule.outputs.principalId
    databaseConnectionString: databaseConnectionString
  }
  dependsOn: [
    functionAppModule
  ]
}

//----------- Function App Settings Deployment ------------
module functionAppSettingsModule 'templates/FunctionAppSettings.bicep' = {
  name: 'siteconf-${buildNumber}'
  params: {
    applicationInsightsKey: applicationInsightsModule.outputs.applicationInsightsKey
    databaseConnectionString: keyVaultModule.outputs.databaseConnectionStringSecretUri
    functionAppName: functionAppModule.outputs.functionAppName
    functionAppRuntime: functionAppRuntime
    storageAccountConnectionString: storageAccountModule.outputs.storageAccountConnectionString
  }
  dependsOn: [
    functionAppModule
  ]
}
