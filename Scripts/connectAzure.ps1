param(
    [Parameter(Mandatory=$true)]$ApplicationId,
    [Parameter(Mandatory=$true)]$TenantId, 
    [Parameter(Mandatory=$true)]$ClientSecret  
)
echo "Reached 1- ${AplicationId}"
echo "Reached 2- ${TenantId}"
echo "Reached 3- ${ClientSecret}"


try {
    $azurePassword = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
    $psCred = New-Object System.Management.Automation.PSCredential($ApplicationId , $azurePassword)
    Connect-AzAccount -Credential $psCred -TenantId $TenantId -ServicePrincipal 
}
catch {
    echo "Reached 5"
    $ErrorMessage = $_.Exception.Message
    echo "Reached 6 - $ErrorMessage"
    Write-Error "Connection to Azure failed with message: $ErrorMessage" 
}
