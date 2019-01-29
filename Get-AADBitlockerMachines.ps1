# Original: https://pwsh.nl/2018/10/26/retrieving-bitlocker-keys-from-azure-ad-with-powershell/
# Requires -Modules AzureAD,AzureRM,PoshRSJob

function Get-AADBitlockerMachines {
    [CmdletBinding()]
    Param
    (
      [pscredential]
      [Parameter(Mandatory)]
      $Credential,
    
      [String]
      [Parameter()]
      $SearchString,

      [Switch]
      [Parameter()]
      $All
    )

    Begin {

        # Import Modules

        Import-Module AzureRM.Profile -Verbose:$False | Out-Null
        if (Get-Module -Name "AzureADPreview" -ListAvailable -Verbose:$False | Out-Null) {
            Import-Module AzureADPreview -Verbose:$False | Out-Null
        } elseif (Get-Module -Name "AzureAD" -ListAvailable -Verbose:$False | Out-Null) {
            Import-Module AzureAD -Verbose:$False | Out-Null 
        }

        # Connect

        Try {
            Connect-AzureAD -Credential $Credential -ErrorAction Stop | Out-Null
        } Catch {
            throw 'Failed to connect to AzureAD'
        }
    
        Try {
            Login-AzureRmAccount -Credential $Credential -ErrorAction Stop | Out-Null
        } Catch {
            throw 'Failed to connect to AzureRM'
        }

        # Setup api call
        try {
            $context = Get-AzureRmContext
        }
        catch {
            throw 'Failed to get AzureRMContext'
        }
        
        $tenantId = $context.Tenant.Id
        $refreshToken = @($context.TokenCache.ReadItems() | Where-Object {$_.tenantId -eq $tenantId -and $_.ExpiresOn -gt (Get-Date)})[0].RefreshToken
        $body = "grant_type=refresh_token&refresh_token=$($refreshToken)&resource=74658136-14ec-4630-ad9b-26e160ff0fc6"
        $apiToken = Invoke-RestMethod "https://login.windows.net/$tenantId/oauth2/token" -Method POST -Body $body -ContentType 'application/x-www-form-urlencoded'
        $header = @{
            'Authorization'          = 'Bearer ' + $apiToken.access_token
            'X-Requested-With'       = 'XMLHttpRequest'
            'x-ms-client-request-id' = [guid]::NewGuid()
            'x-ms-correlation-id'    = [guid]::NewGuid()
        }

        # Search params

        if (!($All)) {
            $userDevices = Get-AzureADDevice -SearchString $SearchString
        } else {
            $userDevices = Get-AzureADDevice -All:$true
        }

    }

    Process {

        $bitLockerKeys = $userDevices | Start-RSJob -Name "$($_.DisplayName)" -ScriptBlock {
            $url = "https://main.iam.ad.ext.azure.com/api/Device/$($_.objectId)"
            $deviceRecord = Invoke-RestMethod -Uri $url -Headers $Using:header -Method Get
            if ($deviceRecord.bitlockerKey.count -ge 1) {
                [PSCustomObject]@{
                    Device        = $deviceRecord.displayName
                    AzureObjectID = $_.objectID
                    DriveType     = $deviceRecord.bitLockerKey.driveType
                    KeyId         = $deviceRecord.bitLockerKey.keyIdentifier
                    RecoveryKey   = $deviceRecord.bitLockerKey.recoveryKey
                }
            }
        } | Wait-RSJob | Receive-RSJob
        
    }

    End {
        
        return $bitLockerKeys
        
    }
    
}