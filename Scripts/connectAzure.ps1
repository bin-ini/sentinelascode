param(
    [Parameter(Mandatory=$true)]$Credentials
)

try {
    $azurePassword = ConvertTo-SecureString ${Credentials.CLIENT_SECRET} -AsPlainText -Force
    $psCred = New-Object System.Management.Automation.PSCredential(${Credentials.CLIENT_ID} , $azurePassword)
    Connect-AzAccount -Credential $psCred -TenantId ${Credentials.TENANT_ID} -Subscription ${Credentials.SUBS_ID} -ServicePrincipal 
}
catch {
    echo "Reached 5"
    $ErrorMessage = $_.Exception.Message
    echo "Reached 6 - $ErrorMessage"
    Write-Error "Connection to Azure failed with message: $ErrorMessage" 
}
