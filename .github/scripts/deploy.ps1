param (
    $templateFile = 'src/infra/main.bicep',
    $templateParameterFile = 'src/infra/main.bicepparam',
    $deploymentStackName = 'sparkstack',
    $resourceGroupName = 'dat535'
)

New-AzResourceGroupDeploymentStack  -TemplateFile $templateFile `
                                    -TemplateParameterFile $templateParameterFile `
                                    -Name $deploymentStackName `
                                    -ResourceGroupName $resourceGroupName `
                                    -DenySettingsMode None `
                                    -Force