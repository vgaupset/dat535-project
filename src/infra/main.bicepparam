using 'main.bicep'

param adminPasswordOrKey = readEnvironmentVariable('PUBLIC_KEY','')
param adminUsername = 'vogadm'

param virtualNetworkName = 'dat535-vnet'
param subnetName = 'dat535-subnet'
