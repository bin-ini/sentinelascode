try {
    $azurePassword = ConvertTo-SecureString ${env:ClientSecret} -AsPlainText -Force
    $psCred = New-Object System.Management.Automation.PSCredential(${env:ClientId} , $azurePassword)
    Connect-AzAccount -Credential $psCred -TenantId ${env:TenantId} -Subscription ${env:SubscriptionId} -ServicePrincipal
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Error "Connection to Azure failed with message: $ErrorMessage" 
}
