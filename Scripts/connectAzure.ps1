
echo "Reached 1- ${env.CLIENT_ID}"
echo "Reached 2- ${env.TENANT_ID}"
echo "Reached 2- ${env.CLIENT_SECRET}"
echo "Reached 3- ${env.SUBS_ID}"


try {
    $azurePassword = ConvertTo-SecureString ${env.CLIENT_SECRET} -AsPlainText -Force
    $psCred = New-Object System.Management.Automation.PSCredential(${env.CLIENT_ID} , $azurePassword)
    Connect-AzAccount -Credential $psCred -TenantId ${env.TENANT_ID} -Subscription ${env.SUBS_ID} -ServicePrincipal 
}
catch {
    echo "Reached 5"
    $ErrorMessage = $_.Exception.Message
    echo "Reached 6 - $ErrorMessage"
    Write-Error "Connection to Azure failed with message: $ErrorMessage" 
}
