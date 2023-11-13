@description('The name of you Virtual Machine.')
param vms array = [
  {
    name: 'namenode'
    vmSize: 'Standard_B2s'
    scriptName: 'namenode-prereq.sh'
    staticPrivateIP: '10.1.0.20'
    publicIp: true
  }
  {
    name: 'datanode1'
    vmSize: 'Standard_B2s'
    scriptName: 'datanode-prereq.sh'
    staticPrivateIP:'10.1.0.21'
    publicIp: false
  }  
  {
    name: 'datanode2'
    vmSize: 'Standard_B2s'
    scriptName: 'datanode-prereq.sh'
    staticPrivateIP:'10.1.0.22'
    publicIp: false
  }  
  {
    name: 'datanode3'
    vmSize: 'Standard_B2s'
    scriptName: 'datanode-prereq.sh'
    staticPrivateIP:'10.1.0.23'
    publicIp: false
  }
]

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${vms[0].name}-${uniqueString(resourceGroup().id)}')

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2004'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the VM')
param vmSize string = 'Standard_B1s'

@description('Name of the VNET')
param virtualNetworkName string = 'vNet'

@description('Name of the subnet in the virtual network')
param subnetName string = 'Subnet'

@description('Name of the Network Security Group')
param networkSecurityGroupName string = 'SecGroupNet'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

var imageReference = {
  'Ubuntu-1804': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2004': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}
var publicIPAddressName = '${vms[0].name}-pip'
var NICNames = [for vm in vms: '${vm.name}-nic']
var osDiskType = 'Standard_LRS'
var subnetAddressPrefix = '10.1.0.0/22'
var addressPrefix = '10.1.0.0/16'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.LinuxAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var maaEndpoint = substring('emptystring', 0, 0)

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-05-01' = [ for (vm, index) in vms : {
  name: NICNames[index]
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vm.staticPrivateIP
          publicIPAddress: vm.publicIP ? {
            id: publicIPAddress.id 
          } : null
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}]

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }      
      {
        name: 'default-allow-RDP'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'HistoryServer'
        properties: {
          priority: 1002
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '18080'
        }
      }
      {
        name: 'lab'
        properties: {
          priority: 1003
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8888'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}


resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource vm_resources 'Microsoft.Compute/virtualMachines@2021-11-01' =[ for (vm, index) in vms: {
  name: vm.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vm.vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface[index].id
        }
      ]
    }
    osProfile: {
      computerName: vm.name
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}]

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = [ for (vm, index) in vms: if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vm_resources[index]
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}]

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = [for (vm, index) in vms: {
  parent: vm_resources[index]
  name: 'custom-script'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'sh ${vm.scriptName}'
      fileUris: [
        'https://raw.githubusercontent.com/vgaupset/dat535-a1/main/src/infra/${vm.scriptName}'
      ]
    }
  }
}]






















// @description('Password for the Virtual Machine.')
// @minLength(12)
// @secure()
// param adminPassword string

// @description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
// param dnsLabelPrefixWin string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

// @description('Name for the Public IP used to access the Virtual Machine.')
// param publicIpName string = 'PublicIPWin'

// @description('Allocation method for the Public IP used to access the Virtual Machine.')
// @allowed([
//   'Dynamic'
//   'Static'
// ])
// param publicIPAllocationMethod string = 'Dynamic'

// @description('SKU for the Public IP used to access the Virtual Machine.')
// @allowed([
//   'Basic'
//   'Standard'
// ])
// param publicIpSku string = 'Basic'

// @description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
// @allowed([
//   '2016-datacenter-gensecond'
//   '2016-datacenter-server-core-g2'
//   '2016-datacenter-server-core-smalldisk-g2'
//   '2016-datacenter-smalldisk-g2'
//   '2016-datacenter-with-containers-g2'
//   '2016-datacenter-zhcn-g2'
//   '2019-datacenter-core-g2'
//   '2019-datacenter-core-smalldisk-g2'
//   '2019-datacenter-core-with-containers-g2'
//   '2019-datacenter-core-with-containers-smalldisk-g2'
//   '2019-datacenter-gensecond'
//   '2019-datacenter-smalldisk-g2'
//   '2019-datacenter-with-containers-g2'
//   '2019-datacenter-with-containers-smalldisk-g2'
//   '2019-datacenter-zhcn-g2'
//   '2022-datacenter-azure-edition'
//   '2022-datacenter-azure-edition-core'
//   '2022-datacenter-azure-edition-core-smalldisk'
//   '2022-datacenter-azure-edition-smalldisk'
//   '2022-datacenter-core-g2'
//   '2022-datacenter-core-smalldisk-g2'
//   '2022-datacenter-g2'
//   '2022-datacenter-smalldisk-g2'
// ])
// param OSVersion string = '2022-datacenter-azure-edition'

// @description('Size of the virtual machine.')
// param vmSizeWin string = 'Standard_B2s'



// @description('Name of the virtual machine.')
// param vmNameWin string = 'dat515-windows'



// var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
// var nicName = 'myVMNic'


// var extensionPublisherWin = 'Microsoft.Azure.Security.WindowsAttestation'

// resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
//   name: storageAccountName
//   location: location
//   sku: {
//     name: 'Standard_LRS'
//   }
//   kind: 'Storage'
// }

// resource publicIpWin 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
//   name: publicIpName
//   location: location
//   sku: {
//     name: publicIpSku
//   }
//   properties: {
//     publicIPAllocationMethod: publicIPAllocationMethod
//     dnsSettings: {
//       domainNameLabel: dnsLabelPrefixWin
//     }
//   }
// }





// resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
//   name: nicName
//   location: location
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'ipconfig1'
//         properties: {
//           privateIPAllocationMethod: 'Dynamic'
//           publicIPAddress: {
//             id: publicIpWin.id
//           }
//           subnet: {
//             id: subnet.id
//           }
//         }
//       }
//     ]
//   }
// }

// resource vmwin 'Microsoft.Compute/virtualMachines@2022-03-01' = {
//   name: vmNameWin
//   location: location
//   properties: {
//     hardwareProfile: {
//       vmSize: vmSizeWin
//     }
//     osProfile: {
//       computerName: vmNameWin
//       adminUsername: adminUsername
//       adminPassword: adminPassword
//     }
//     storageProfile: {
//       imageReference: {
//         publisher: 'MicrosoftWindowsServer'
//         offer: 'WindowsServer'
//         sku: OSVersion
//         version: 'latest'
//       }
//       osDisk: {
//         createOption: 'FromImage'
//         managedDisk: {
//           storageAccountType: 'StandardSSD_LRS'
//         }
//       }
//       dataDisks: [
//         {
//           diskSizeGB: 1023
//           lun: 0
//           createOption: 'Empty'
//         }
//       ]
//     }
//     networkProfile: {
//       networkInterfaces: [
//         {
//           id: nic.id
//         }
//       ]
//     }
//     diagnosticsProfile: {
//       bootDiagnostics: {
//         enabled: true
//         storageUri: storageAccount.properties.primaryEndpoints.blob
//       }
//     }
//     securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
//   }
// }

// resource vmExtensionWin 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
//   parent: vmwin
//   name: extensionName
//   location: location
//   properties: {
//     publisher: extensionPublisherWin
//     type: extensionName
//     typeHandlerVersion: extensionVersion
//     autoUpgradeMinorVersion: true
//     enableAutomaticUpgrade: true
//     settings: {
//       AttestationConfig: {
//         MaaSettings: {
//           maaEndpoint: maaEndpoint
//           maaTenantName: maaTenantName
//         }
//       }
//     }
//   }
// }

// output hostnameWin string = publicIpWin.properties.dnsSettings.fqdn









































output adminUsername string = adminUsername
output hostname string = publicIPAddress.properties.dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${publicIPAddress.properties.dnsSettings.fqdn}'
