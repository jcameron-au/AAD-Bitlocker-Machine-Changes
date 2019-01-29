# AAD Bitlocker Machine Changes

This script pulls machines from Azure Active Directory and checks if they're encrypted with BitLocker. If they are, it will log them in JSON format including their bitlocker details and Azure object id. 

Each time this runs it will compare to the previous machine log and email a report of any added or removed machines, as well as any machines that have differing keys. It will then email the report to notify of changes.

## Requirements

All of these modules can be fetched from the PSGallery.

* [AzureAD](https://www.powershellgallery.com/packages/AzureAD)
* [AzureRM](https://www.powershellgallery.com/packages/AzureRM)
* [PoshRSJob](https://www.powershellgallery.com/packages/PoshRSJob)

##### Note about PoshRSJob:

You could edit the script and remove the requirement of PoshRSJob, but this cut down down the time it took for ~900-1000 machines from over 30 minutes to under 15.

        PS > Measure-Command {Get-AzureADBitLockerKeysForUser -Credential $cred}

        Days              : 0
        Hours             : 0
        Minutes           : 27
        Seconds           : 35
        Milliseconds      : 395
        Ticks             : 16553952887
        TotalDays         : 0.019159667693287
        TotalHours        : 0.459832024638889
        TotalMinutes      : 27.5899214783333
        TotalSeconds      : 1655.3952887
        TotalMilliseconds : 1655395.2887

        PS > Measure-Command {Get-AADBitlockerMachines -Credential $cred -All}

        Days              : 0
        Hours             : 0
        Minutes           : 14
        Seconds           : 12
        Milliseconds      : 894
        Ticks             : 8528945166
        TotalDays         : 0.0098714643125
        TotalHours        : 0.2369151435
        TotalMinutes      : 14.21490861
        TotalSeconds      : 852.8945166
        TotalMilliseconds : 852894.5166


## Installation

Download the repo, and extract somewhere.
Inspect all of the scripts and make sure you're happy with what they do, and how they do it.
Edit the `mailParams` hashtable in `Send-AABitlockerEmail.ps1` which your desired details.
Run `Start-AADBitlockerReport.ps1`.

You can set this up as a scheduled task as well. I use seperate accounts for everything so by default you can see two different credentials being passed, but you can edit this howevery you like.

## Screenshots

![Report Output](https://i.imgur.com/4Ff6DDI.png)


## Thanks

Massive thanks to:

 * Gerbrand van der Weg

He has an [excellent post on his blog](https://pwsh.nl/2018/10/26/retrieving-bitlocker-keys-from-azure-ad-with-powershell/) explaining how to fetch the machines from AAD and feed them into the Microsoft API. So far I have found no other way of retrieveing this info from AAD and so he is undoubtedly a genius.

* Boe Prox 

Boe is the master of multithreading and created [PoshRSJob](https://github.com/proxb/PoshRSJob). I've done manual runspace stuff and it's a nightmare as I am not a C# guy. I love his module and promote it any chance I get.
