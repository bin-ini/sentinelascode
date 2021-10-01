param(
    [Parameter(Mandatory=$true)]$Workspace,
    [Parameter(Mandatory=$true)]$RulesFile
)
 echo "Reached 1- ${env.PATH}"

#Adding AzSentinel module
Install-Module AzSentinel -Scope CurrentUser -Force
Import-Module AzSentinel

echo "Reached 2- ${PATH}"

#Name of the Azure DevOps artifact
$artifactName = "RulesFile"

echo "Reached 2.1- ${artifactName}"

#Build the full path for the analytics rule file
$artifactPath = Join-Path $env:Pipeline_Workspace $artifactName 

echo "Reached 2.2- ${artifactPath}"

$rulesFilePath = Join-Path $artifactPath $RulesFile

echo "Reached 3- ${artifactPath}"
echo "Reached 4- ${rulesFilePath}"

try {
    echo "Reached 5- ${rulesFilePath}"
    Import-AzSentinelAlertRule -WorkspaceName $Workspace -SettingsFile $rulesFilePath
}
catch {
    echo "Reached 5"
    $ErrorMessage = $_.Exception.Message
    echo "Reached 6"
    Write-Error "Rule import failed with message: $ErrorMessage" 
}
