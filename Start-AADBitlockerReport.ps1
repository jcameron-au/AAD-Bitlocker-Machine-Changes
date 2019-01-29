function Start-AADBitlockerReport {
    [CmdletBinding()]
    Param()

    <# I use these for running as scheduled.
       Seperate accounts for pulling info and sending email
    $AADCredential = Import-Clixml -Path $PSScriptRoot\a.xml
    $SMTPCredential = Import-Clixml -Path $PSScriptRoot\b.xml
    #>

    Start-Transcript -Path "$PSScriptRoot\Logs\bitlocker_machines_log_$((Get-Date -Format FileDateTime).ToString()).txt"

    $startDate = Get-Date
    Write-Verbose "Started at: [$($startDate)]"

    . $PSScriptRoot\Get-AADBitlockerMachines.ps1
    . $PSScriptRoot\Compare-AADBitlockerMachines.ps1
    . $PSScriptRoot\Send-AADBitlockerEmail.ps1

    # Get Output from previous run
    try {
        $previousMachines = Get-ChildItem "$PSScriptRoot\Machines" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content | ConvertFrom-Json
        Write-Verbose "Got list of previous machines."
    }
    catch { 
        Write-Warning 'Error fetching previous machines.'
        Stop-Transcript
        exit
    }

    # Get all machines from AAD and their keys
    try {
        $bitlockerAADMachines = Get-AADBitlockerMachines -Credential $AADCredential -All
    }
    catch { Write-Verbose 'Error fetching machines.'}

    if ($bitlockerAADMachines) {
    
        # Write the list to Machines for next time
        $bitlockerAADMachines | ConvertTo-Json | Out-File -FilePath "$PSScriptRoot\Machines\bitlocker_machines_$((Get-Date -Format FileDateTime).ToString()).txt"

        # Compare previous list with current list and get changes
        $machineChanges = Compare-AADBitlockerMachines -ReferenceObject $previousMachines -DifferenceObject $bitlockerAADMachines

        if ($machineChanges) {

            Send-AADBitlockerEmail -Content $machineChanges -smtpCredential $SMTPCredential
            
        } else {
            
            $emptyContent = [pscustomobject]@{
                DisplayName = ''
                AzureObjectID = ''
                Status = ''
            }
            
            Send-AADBitlockerEmail -Content $emptyContent -smtpCredential $SMTPCredential
            Write-Verbose 'No changes were made to the bitlocker list since last run.'
        }
      
    } else {
        Write-Verbose 'bitlocker aad machines is empty'
    }

    $finishDate = Get-Date
    $scriptDifference = $finishDate - $startDate
    $scriptLength = "Script took: [{0}d:{1}h:{2}m:{3}s]" -f $scriptDifference.Days,$scriptDifference.Hours,$scriptDifference.Minutes,$scriptDifference.Seconds
    Write-Verbose "Finished at: [$($finishDate.ToString())]"
    Write-Verbose "$scriptLength"

    Stop-Transcript
}

Start-AADBitlockerReport -Verbose