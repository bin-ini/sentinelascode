param(
    [Parameter(Mandatory=$true)]$Workspace,
    [Parameter(Mandatory=$true)]$resourceGroup,
    [Parameter(Mandatory=$true)]$AnalyticsRulesFolder
)

Write-Host "Folder is: $($AnalyticsRulesFolder)"

$armTemplateFiles = Get-ChildItem -Path $AnalyticsRulesFolder -Filter *arm.json

Write-Host "Files are: " $armTemplateFiles

foreach ($armTemplate in $armTemplateFiles) {
    try {
        New-AzResourceGroupDeployment -Workspace $Workspace -ResourceGroupName $resourceGroup -TemplateFile $armTemplate 
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Error "Analytics Rules deployment failed with message: $ErrorMessage" 
    }
}
