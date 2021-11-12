param(
    [Parameter(Mandatory=$true)]$Workspace,
    [Parameter(Mandatory=$true)]$RulesFile
    
)
 echo "Reached 1- ${env.PATH}"

#Adding AzSentinel module
Install-Module AzSentinel -Scope CurrentUser -Force
Import-Module AzSentinel -AllowClobber -Force

echo "Reached 2- ${PATH}"
echo "Reached 2.0- $artifactName"

#Name of the Azure DevOps artifact
$artifactName = "AnalyticsRules"

echo "Reached 2.1- ${artifactName}"

#Build the full path for the analytics rule file
$artifactPath = Join-Path $env:Pipeline_Workspace $artifactName 

echo "Reached 2.2- ${artifactPath}"
echo "Reached 2.3- ${env:SubscriptionId}"
echo "Reached 2.4 azureSubscription - ${env:azureSubscription}"
echo "Reached 2.4- ${env:ResourceGroup}"
echo "Reached 2.5- ${env:Pipeline_Workspace}"
echo "Reached 2.6- ${env:TenantId}"


$rulesFilePath = Join-Path $artifactPath $RulesFile

echo "Reached 3- ${artifactPath}"
echo "Reached 4- ${rulesFilePath}"

try {
    echo "Reached 5- ${rulesFilePath}"
    echo "Reached 6- ${Workspace}"
    Import-AzSentinelAlertRule -WorkspaceName $Workspace -SettingsFile $rulesFilePath
}
catch {
    echo "Reached 5"
    $ErrorMessage = $_.Exception.Message
    echo "Reached 6 - $ErrorMessage"
    Write-Error "Rule import failed with message: $ErrorMessage" 
}
