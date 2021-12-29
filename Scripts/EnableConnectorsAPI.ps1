param(
    [Parameter(Mandatory=$true)]$ResourceGroup,
    [Parameter(Mandatory=$true)]$Workspace,
    [Parameter(Mandatory=$true)]$ConnectorsFile
)

#Name of the Azure DevOps artifact
$artifactName = "Connectors"

#Build the full path for the analytics rule file
$artifactPath = Join-Path $env:Pipeline_Workspace $artifactName 
$connectorsFilePath = Join-Path $artifactPath $ConnectorsFile


#Resource URL to authentincate against
$Resource = "https://management.azure.com/"

#Urls to be used for Sentinel API calls
$baseUri = "https://management.azure.com/subscriptions/${env:SubscriptionId}/resourceGroups/${ResourceGroup}/providers/Microsoft.OperationalInsights/workspaces/${Workspace}"

echo "baseUri - ${baseUri}"

$RequestAccessTokenUri = "https://login.microsoftonline.com/${env:TenantId}/oauth2/token"

echo "RequestAccessTokenUri - ${RequestAccessTokenUri}"

$body = "grant_type=client_credentials&client_id=${env:ClientId}&client_secret=${env:ClientSecret}&resource=${Resource}"

echo "body - ${body}"

$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'

echo "Token - ${Token}"

Write-Host "Print Token" -ForegroundColor Green
Write-Output $Token

$Headers = @{}

$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")

$Headers.Add("Content-Type", "application/json")

#Getting all rules from file
$connectors = Get-Content -Raw -Path $connectorsFilePath | ConvertFrom-Json

foreach ($connector in $connectors.connectors) {
    Write-Host "Processing alert rule: " -NoNewline 
    Write-Host "$($connector.kind)" -ForegroundColor Green

    #AzureAdvancedThreatProtection connector
    if ($connector.kind -eq "AzureAdvancedThreatProtection") {
        $aatpEnabled = $false
        $guid = (New-Guid).Guid
        $etag = ""
        $connectorBody = ""
        
        $uri = "$baseUri/providers/Microsoft.SecurityInsights/dataConnectors/?api-version=2020-01-01"
        
        #Query for connected datasources and search AzureAdvancedThreatProtection
        try {
            $result = Invoke-webrequest -Uri $uri -Method Get -Headers $Headers | ConvertFrom-Json
            
            echo "result defender - ${result}"
            
            foreach ($value in $result.value){
                # Check if aatpEnabled is already enabled (assuming there will be only one aatpEnabled per workspace)
                if ($value.kind -eq "AzureAdvancedThreatProtection") {
                    Write-Host "Successfully queried data connctor $($value.kind) - already enabled"
                    Write-Verbose $value
                    $guid = $value.name
                    $etag = $value.etag
                    $aatpEnabled = $true
                    break
                }
            }
        }
        catch {
            $errorReturn = $_
        }

        if ($aatpEnabled) {
            # Compose body for connector update scenario
            Write-Host "Updating data connector $($connector.kind)"
            Write-Verbose "Name: $guid"
            Write-Verbose "Etag: $etag"
        
            $connectorBody = @{
                id = "${baseUri}/providers/Microsoft.SecurityInsights/dataConnectors/${guid}"
                name = $guid
                etag = $etag
                type = "Microsoft.SecurityInsights/dataConnectors"
                kind = $connector.kind
                properties = @{
                    tenantId = ${env:TenantId}
                    dataTypes = @{
                        alerts = @{
                            state = "enabled"
                        }
                    }
                }
            }
        }
        else {
            # Compose body for connector enable scenario
            Write-Host "$($connector.kind) data connector is not enabled yet"
            Write-Host "Enabling data connector $($connector.kind)"
            Write-Verbose "Name: $guid"
     
            $connectorBody = @{
                id = "${baseUri}/providers/Microsoft.SecurityInsights/dataConnectors/${guid}"
                name = $guid
                type = "Microsoft.SecurityInsights/dataConnectors"
                kind = $connector.kind
                properties = @{
                    tenantId = ${env:TenantId}
                    dataTypes = @{
                        alerts = @{
                            state = "enabled"
                        }
                    }
                }
            }
        }

        # Enable or update AzureAdvancedThreatProtection with http put method
        $uri = "${baseUri}/providers/Microsoft.SecurityInsights/dataConnectors/${guid}?api-version=2020-01-01"
        
        $connectorBody | Out-String | Write-Host
        
        try {
            $result = Invoke-webrequest -Uri $uri -Method Put -Headers $Headers -Body ($connectorBody | ConvertTo-Json -Depth 4 -EnumsAsStrings)
            
            if ($aatpEnabled) {
                Write-Host "Successfully updated data connector: $($connector.kind) with status: $($result.StatusDescription)"
            }
            else {
                Write-Host "Successfully enabled data connector: $($connector.kind) with status: $($result.StatusDescription)"
            }
            Write-Verbose ($body.Properties | Format-List | Format-Table | Out-String)
        }
        catch {
            $errorReturn = $_
            $errorResult = ($errorReturn | ConvertFrom-Json ).error
            Write-Verbose $_
            Write-Error "Unable to invoke webrequest with error message: $($errorResult.message)" -ErrorAction Stop
        }
    }
}
#Office365 connector
if ($connector.kind -eq "Office365") {
        $O365Enabled = $false
        $guid = (New-Guid).Guid
        $etag = ""
        $connectorBody = ""
        
        $uri = "$baseUri/providers/Microsoft.SecurityInsights/dataConnectors/?api-version=2020-01-01"
        
        #Query for connected datasources and search Office365
        try {
            $result = Invoke-webrequest -Uri $uri -Method Get -Headers $Headers | ConvertFrom-Json
            
            foreach ($value in $result.value){
                # Check if O365Enabled is already enabled (assuming there will be only one aatpEnabled per workspace)
                if ($value.kind -eq "Office365") {
                    Write-Host "Successfully queried data connctor $($value.kind) - already enabled"
                    Write-Verbose $value
                    $guid = $value.name
                    $etag = $value.etag
                    $O365Enabled = $true
                    break
                }
            }
        }
        catch {
            $errorReturn = $_
        }

        if ($O365Enabled) {
            # Compose body for connector update scenario
            Write-Host "Updating data connector $($connector.kind)"
            Write-Verbose "Name: $guid"
            Write-Verbose "Etag: $etag"
        
            $connectorBody = @{
                id = "${baseUri}/providers/Microsoft.SecurityInsights/dataConnectors/${guid}"
                name = $guid
                etag = $etag
                type = "Microsoft.SecurityInsights/dataConnectors"
                kind = $connector.kind
                properties = @{
                    tenantId = ${env:TenantId}
                    dataTypes = @{
                        sharePoint = @{
                            state = "enabled"
                        }
                        exchange = @{
                            state = "enabled"
                        }
                        teams = @{
                            state = "enabled"
                        }
                    }
                }
            }
        }
        else {
            # Compose body for connector enable scenario
            Write-Host "$($connector.kind) data connector is not enabled yet"
            Write-Host "Enabling data connector $($connector.kind)"
            Write-Verbose "Name: $guid"
     
            $connectorBody = @{
                id = "${baseUri}/providers/Microsoft.SecurityInsights/dataConnectors/${guid}"
                name = $guid
                type = "Microsoft.SecurityInsights/dataConnectors"
                kind = $connector.kind
                properties = @{
                    tenantId = ${env:TenantId}
                    dataTypes = @{
                        sharePoint = @{
                            state = "enabled"
                        }
                        exchange = @{
                            state = "enabled"
                        }
                        teams = @{
                            state = "enabled"
                        }
                    }
                }
            }
        }

        # Enable or update Office365 with http put method
        $uri = "${baseUri}/providers/Microsoft.SecurityInsights/dataConnectors/${guid}?api-version=2020-01-01"
        
        $connectorBody | Out-String | Write-Host
        
        try {
            $result = Invoke-webrequest -Uri $uri -Method Put -Headers $Headers -Body ($connectorBody | ConvertTo-Json -Depth 4 -EnumsAsStrings)
            
            if ($O365Enabled) {
                Write-Host "Successfully updated data connector: $($connector.kind) with status: $($result.StatusDescription)"
            }
            else {
                Write-Host "Successfully enabled data connector: $($connector.kind) with status: $($result.StatusDescription)"
            }
            Write-Verbose ($body.Properties | Format-List | Format-Table | Out-String)
        }
        catch {
            $errorReturn = $_
            $errorResult = ($errorReturn | ConvertFrom-Json ).error
            Write-Verbose $_
            Write-Error "Unable to invoke webrequest with error message: $($errorResult.message)" -ErrorAction Stop
        }
    }
}


# Azure Active Directory Audit/SignIn logs - requires special call and is therefore not connectors file
# Be aware that you executing SPN needs Owner rights on tenant scope for this operation, can be added with following CLI
# az role assignment create --role Owner --scope "/" --assignee {13ece749-d0a0-46cf-8000-b2552b520631}
$uri = "${Resource}providers/microsoft.aadiam/diagnosticSettings/AzureSentinel_${Workspace}?api-version=2017-04-01"
$connectorBody = @"

{
    "id": "/providers/microsoft.aadiam/diagnosticSettings/AzureSentinel_${Workspace}",
    "name": "AzureSentinel_${Workspace}",
    "properties": {
        "logs": [
            {
                "category": "SignInLogs",
                "enabled": true,
                "retentionPolicy": {
                    "days": 0,
                    "enabled": false
                }
            },
            {
                "category": "AuditLogs",
                "enabled": true,
                "retentionPolicy": {
                    "days": 0,
                    "enabled": false
                }
            }
        ],
        "metrics": [],
        "workspaceId": "/subscriptions/${env:SubscriptionId}/resourceGroups/${ResourceGroup}/providers/Microsoft.OperationalInsights/workspaces/${Workspace}"
    }
}
"@
Write-Output $uri
Write-Output $connectorBody

try {
    $result = Invoke-webrequest -Uri $uri -Method Put -Headers $Headers -Body ($connectorBody)
    Write-Host "Successfully updated data connector: Azure Active Directory with status: $($result.StatusDescription)"
}
catch {
    $errorReturn = $_
    $errorResult = ($errorReturn | ConvertFrom-Json ).error
    
    echo "Errorcode defender5 - $errorResult"
    
    Write-Verbose $_
    Write-Error "Unable to invoke webrequest with error message: $($errorResult.message)" -ErrorAction Stop
}
