param(
    [Parameter(Mandatory=$true)]$applicationId,
    [Parameter(Mandatory=$true)]$tenantId,   
    [Parameter(Mandatory=$true)]$clientSecret  
)
echo "Reached 1- ${aplicationId}"
echo "Reached 2- ${tenantId}"
echo "Reached 3- ${clientSecret}"


try {
    $azurePassword = ConvertTo-SecureString $clientSecret -AsPlainText -Force
    $psCred = New-Object System.Management.Automation.PSCredential($applicationId , $azurePassword)
    Connect-AzAccount -Credential $psCred -TenantId $tenantId  -ServicePrincipal 
}
catch {
    echo "Reached 5"
    $ErrorMessage = $_.Exception.Message
    echo "Reached 6 - $ErrorMessage"
    Write-Error "Connection to Azure failed with message: $ErrorMessage" 
}
