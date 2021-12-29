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

    #AzureActivity connector
    if ($connector.kind -eq "AzureActivity") {
    
    echo "AzureActivity - ${connector.kind}"
    
        $uri = "$baseUri/datasources/${env:SubscriptionId}?api-version=2020-03-01-preview"
        $connectorBody = ""
        $activityEnabled = $false

        #Check if AzureActivity is already connected (there is no better way yet) [assuming there is only one AzureActivity from same subscription connected]
        try {
            # AzureActivity is already connected, compose body with existing etag for update
            $result = Invoke-webrequest -Uri $uri -Method Get -Headers $Headers | ConvertFrom-Json
            
            echo "result - ${result}"
            
            Write-Host "Successfully queried data connctor ${connector.kind} - already enabled"
            Write-Verbose $result
            Write-Host "Updating data connector $($connector.kind)"

            $activityEnabled = $true
            $connectorProperties = @{
                linkedResourceId = "/subscriptions/${env:SubscriptionId}/providers/microsoft.insights/eventtypes/management"
            }        
            
            $connectorBody = @{
                kind = $result.kind
                properties = $connectorProperties
                id = $result.id
                etag = $result.etag
                name = $result.name
                type = $result.type
            }
        }
        catch { 
            $errorReturn = $_
            #If return code is 404 we are assuming AzureActivity is not enabled yet

            echo "Errorcode activity - $_.Exception.Response.StatusCode.value__"

            if ($_.Exception.Response.StatusCode.value__ = 404) {
                Write-Host "Data connector $($connector.kind) is not enabled"  
                Write-Verbose $_
                Write-Host "Enabling data connector $($connector.kind)"

                $activityEnabled = $false
                $connectorProperties = @{
                    linkedResourceId = "/subscriptions/${env:SubscriptionId}/providers/microsoft.insights/eventtypes/management"
                }        
                
                $connectorBody = @{
                    kind = $connector.kind
                    properties = $connectorProperties
                    id = $connector.id
                    name = $connector.name
                    type = $connector.type
                } 
            }
            #Any other eeror code is interpreted as error 
            else {
                $errorResult = ($errorReturn | ConvertFrom-Json ).error
                Write-Verbose $_.Exception.Message
                Write-Error "Unable to invoke webrequest with error message: $($errorResult.message)" -ErrorAction Stop           
            }
        }

        #Enable or Update AzureActivity Connector with http puth method
        try {
            $result = Invoke-webrequest -Uri $uri -Method Put -Headers $Headers -Body ($connectorBody | ConvertTo-Json -EnumsAsStrings)
            if ($activityEnabled) {
                Write-Host "Successfully update data connector: $($connector.kind) with status: $($result.StatusDescription)"
            }
            else {
                Write-Host "Successfully enabled data connector: $($connector.kind) with status: $($result.StatusDescription)"
            }
             
             Write-Verbose ($body.Properties | Format-List | Format-Table | Out-String)
        }
        catch {
            $errorReturn = $_
            $errorResult = ($errorReturn | ConvertFrom-Json ).error
            
            echo "Errorcode defender1 - $errorResult"
            
            Write-Verbose $_.Exception.Message
            Write-Error "Unable to invoke webrequest with error message: $($errorResult.message)" -ErrorAction Stop
        }  
    }

    #MicrosoftDefenderforCloud connector
    if ($connector.kind -eq "MicrosoftDefenderforCloud") {
    
        echo "MicrosoftDefenderforCloud - ${connector.kind}"
            
        $ascEnabled = $false
        $guid = (New-Guid).Guid
        $etag = ""
        $connectorBody = ""
        $uri = "$baseUri/providers/Microsoft.SecurityInsights/dataConnectors/?api-version=2020-01-01"

        #Query for connected datasources and search MicrosoftDefenderforCloud
        try {
            $result = Invoke-webrequest -Uri $uri -Method Get -Headers $Headers | ConvertFrom-Json
            
            echo "result defender2 - $result"            
            
            echo "result defender - ${result}"
            
            foreach ($value in $result.value){
                # Check if ASC is already enabled (assuming there will be only one ASC per workspace)
                if ($value.kind -eq "MicrosoftDefenderforCloud") {
                    Write-Host "Successfully queried data connctor $($value.kind) - already enabled"
                    Write-Verbose $value
                    $guid = $value.name
                    $etag = $value.etag
                    $ascEnabled = $true
                    break
                }
            }
        }
        catch {
            $errorReturn = $_
            echo "Errorcode defender2 - $errorReturn"
        }

        if ($ascEnabled) {
            # Compose body for connector update scenario
            Write-Host "Updating data connector $($connector.kind)"
            Write-Verbose "Name: $guid"
            Write-Verbose "Etag: $etag"
           
           echo "ascEnabled defender3 - $ascEnabled"
        
            $connectorBody = @{
                id = "${baseUri}/providers/Microsoft.SecurityInsights/dataConnectors/${guid}"
                name = $guid
                etag = $etag
                type = "Microsoft.SecurityInsights/dataConnectors"
                kind = $connector.kind
                properties = @{
                    subscriptionId = ${env:SubscriptionId}
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
            
            echo "Not ascEnabled defender3"

            $connectorBody = @{
                id = "${baseUri}/providers/Microsoft.SecurityInsights/dataConnectors/${guid}"
                name = $guid
                type = "Microsoft.SecurityInsights/dataConnectors"
                kind = $connector.kind
                properties = @{
                    subscriptionId = ${env:SubscriptionId}
                    dataTypes = @{
                        alerts = @{
                            state = "enabled"
                        }
                    }
                }
            }
        }

        # Enable or update MicrosoftDefenderforCloud with http put method
        $uri = "${baseUri}/providers/Microsoft.SecurityInsights/dataConnectors/${guid}?api-version=2020-01-01"

        echo "uri defender3 - $uri"
        echo "Headers defender3 - $Headers"
        
        $connectorBody | Out-String | Write-Host
        ${connectorBody.properties} | Out-String | Write-Host
        $Headers | Out-String | Write-Host
        
        try {
            $result = Invoke-webrequest -Uri $uri -Method Put -Headers $Headers -Body ($connectorBody | ConvertTo-Json -Depth 4 -EnumsAsStrings)
            
            echo "result defender3 - $result"
            
            if ($ascEnabled) {
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
            
            echo "Errorcode defender3 - $errorResult"
            
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
