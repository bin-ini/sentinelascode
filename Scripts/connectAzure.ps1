echo "SUBS_ID - ${env:SUBS_ID}, CLIENT_ID - ${env:CLIENT_ID}"

try {
    Disable-AzContextAutosave
    $azurePassword = ConvertTo-SecureString ${env:CLIENT_SECRET} -AsPlainText -Force
    $psCred = New-Object System.Management.Automation.PSCredential(${env:CLIENT_ID} , $azurePassword)
    Connect-AzAccount -Credential $psCred -TenantId ${env:TENANT_ID} -Subscription ${env:SUBS_ID} -ServicePrincipal
    Enable-AzContextAutosave
}
catch {
    echo "Reached 5"
    $ErrorMessage = $_.Exception.Message
    echo "Reached 6 - $ErrorMessage"
    Write-Error "Connection to Azure failed with message: $ErrorMessage" 
}
