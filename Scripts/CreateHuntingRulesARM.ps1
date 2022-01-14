param(
    [Parameter(Mandatory=$true)]$Workspace,
    [Parameter(Mandatory=$true)]$resourceGroup,
    [Parameter(Mandatory=$true)]$HuntingRulesFolder
)

Write-Host "Folder is: $($HuntingRulesFolder)"

$armTemplateFiles = Get-ChildItem -Path $HuntingRulesFolder -Filter *arm.json

Write-Host "Files are: " $armTemplateFiles

foreach ($armTemplate in $armTemplateFiles) {
    try {
        New-AzResourceGroupDeployment -Workspace $Workspace -ResourceGroupName $resourceGroup -TemplateFile $armTemplate 
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Error "Hunting Rules deployment failed with message: $ErrorMessage" 
    }
}
