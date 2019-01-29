function Compare-AADBitlockerMachines {
    [CmdletBinding()]
    Param
    (
      [PSCustomObject]
      [Parameter(Mandatory)]
      $ReferenceObject,
    
      [PSCustomObject]
      [Parameter(Mandatory)]
      $DifferenceObject
    )

    Begin {

        [System.Collections.ArrayList]$changedMachines = @()

    }

    Process {
        # Comparing manually, using Sort-Object uses the order of the objects? and gave wrong output

        # Check previous list for devices not in new list, ie removed
        foreach ($device in $ReferenceObject) {
            if (!($DifferenceObject.Device.Contains($device.Device))) {

                Write-Verbose "$($Device.Device) is not in new list"
                
                $changedMachines += [PSCustomObject]@{
                    DisplayName = $device.Device
                    AzureObjectID = $device.AzureObjectID
                    Status = 'Removed'
                }

            # if they are in the new list, check they have the same keys
            # I'm checking KeyID not Recovery Key, but the recoverykey is bound to it
            } else {
                
                Write-Verbose "$($Device.Device) is in new list"
                $DifferenceDeviceObject = $DifferenceObject | Where-Object {$_.Device -eq $device.Device}

                foreach ($bitlockerKey in $device.KeyID) {
                    Write-Verbose "Checking key [$bitlockerKey]"
                    if ($bitlockerKey -notin $DifferenceDeviceObject.KeyID) {
                        Write-Verbose "Old key no longer valid"
                        $changedMachines += [PSCustomObject]@{
                            DisplayName = $device.Device
                            AzureObjectID = $device.AzureObjectID
                            Status = 'New KeyID'
                        } # end pscustom
                    } #end if
                } #end foreach
           }# end else
        }

        # Check new list for devices not in previous list, ie newly added
        foreach ($device in $DifferenceObject) {
            if (!($ReferenceObject.Device.Contains($device.Device))) {

                Write-Verbose "$($Device.Device) is not in previous list"
                
                $changedMachines += [PSCustomObject]@{
                    DisplayName = $device.Device
                    AzureObjectID = $device.AzureObjectID
                    Status = 'Added'
                }
            }
        }

    } # end process

    End {
        return $changedMachines
    }
}