@description('Key Vault name')
param name string

@description('Key vault location')
param location string

@description('Key Vault SKU')
@allowed([
  'standard'
  'premium'
])
param sku string

@description('Function App principal id')
param funcPrincipalId string

@description('Function App tenant id')
param funcTenantId string

@description('Key Vault Secret: Database Connection String')
@secure()
param databaseConnectionString string

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: name
  location: location
  properties: {
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true
    sku: {
      family: 'A'
      name: sku
    }
    accessPolicies: [
      {
        objectId: funcPrincipalId
        tenantId: funcTenantId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

resource databaseConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: '${name}/databaseConnectionString'
  properties: {
    value: databaseConnectionString
  }
  dependsOn: [
    keyVault
  ]
}

output databaseConnectionStringSecretUri string = databaseConnectionStringSecret.properties.secretUri
