@description('App Service Plan name')
param name string

@description('App Service Plan location')
param location string

@description('App Service Plan operating system')
@allowed([
  'Windows'
  'Linux'
])
param os string

var reserved = os == 'Linux' ? true : false

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: name
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
  }
  properties: {
    reserved: reserved
  }
}

output planId string = appServicePlan.id
