param(
    [Parameter(Mandatory=$true)]$resourceGroup,
    [Parameter(Mandatory=$true)]$AnalyticsRulesFolder
)

Write-Host "Folder is: $($AnalyticsRulesFolder)"

$armTemplateFiles = Get-ChildItem -Path $AnalyticsRulesFolder -Filter *.json

Write-Host "Files are: " $armTemplateFiles

foreach ($armTemplate in $armTemplateFiles) {
    try {
        New-AzResourceGroupDeployment -ResourceGroupName $resourceGroup -TemplateFile $armTemplate 
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Error Analytics Rules deployment failed with message: $ErrorMessage" 
    }
}
