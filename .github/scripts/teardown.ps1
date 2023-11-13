param (
    $deploymentStackName = 'sparkstack',
    $resourceGroupName = 'dat535'
)

Remove-AzResourceGroupDeploymentStack   -Name $deploymentStackName `
                                        -ResourceGroupName $resourceGroupName `
                                        -DeleteResources `
                                        -Force