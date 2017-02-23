<#
    .SYNOPSIS
        Cleanes specified office 365 destination
         
    .DESCRIPTION
        Connects to specified destination, removes all licensed mailboxes and creates mailboxes from the list below
        and assigns active licenses to them
    
    .EXAMPLE
        .\Clean-Users 32
    
        Removes and readds all 25 users in @devcmp32.onmicrosoft.com destination
#>

param 
(
    [Parameter(Mandatory=$true,
               Position=1,
               ValueFromPipeline=$false,
               ValueFromPipelineByPropertyName=$False)]
    [int]$domainNumber
)

$fullDomain = "devcmp" + $domainNumber + ".onmicrosoft.com"
if ($fullDomain -like "devcmp*.onmicrosoft.com")
{

    # connect to O365
    Write-Host "Connecting to O365" -ForegroundColor Cyan

    $AdminName = Get-Content "D:\Credentials\Username.txt"
    $FullAdminName = $AdminName + "@" + $fullDomain
    $Pass = Get-Content "D:\Credentials\Password.txt" | ConvertTo-SecureString
    $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $FullAdminName, $Pass
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection
    Import-PSSession $Session
    Connect-MsolService -Credential $Cred
    Write-Host "Session established to: $fullDomain" -ForegroundColor Green


    # Removing all licensed users
    Write-Host "Removing licensed Users" -ForegroundColor Cyan
    $removeUsers = Get-MsolUser | where { ($_.islicensed -eq $true) -and ($_.userPrincipalName -notlike "$AdminName*") }
    Foreach ($RU in $removeUsers)
    {
        $rupn = $ru.userPrincipalName
        Remove-MsolUser -UserPrincipalName $rupn -Force | Out-Null
        Remove-MsolUser -UserPrincipalName $rupn -RemoveFromRecycleBin -Force | Out-Null
        Write-Output "User $rupn removed"
    }

    # Remove all other items (shared, room, eqipment)
    Write-Host "Cleaning up other accounts" -ForegroundColor Cyan
  
    $NLusers = Get-MsolUser | where {$_.isLicensed -eq $false}
    foreach ($nlu in $NLusers)
    {
        $nlupn = $nlu.userPrincipalName
        Remove-MsolUser -UserPrincipalName $nlupn -Force | Out-Null
        Remove-MsolUser -UserPrincipalName $nlupn -RemoveFromRecycleBin -Force | Out-Null
        Write-Output "User $nlupn removed"
    }
    
    Write-Host "Waiting for dust to settle down" -ForegroundColor Cyan
    Start-Sleep -Seconds 300
    

    # Import data from CSV files
    $CSVPath = "D:\CSV_Data"

    # Crate user account from users in the array
    Write-Host "Creating users on the destination" -ForegroundColor Cyan

    $75Users = Import-Csv $CSVPath\75users.csv
    $75Users | ForEach-Object {
        $User = $_.displayName   
        $u = $user.Split(" ")
    
        $first = $u[0]
        $last = $u[1]
    
        $upn = $first + "." + $last + "@" + $fullDomain

        if ( (Get-MsolUser).userprincipalname -like $upn )
        {
            Write-Output "User $upn already exists"
            Write-Output "Checking if user is licensed"
            if ( (Get-MsolUser -UserPrincipalName $upn).isLicensed -eq $true )
            {
                Write-Output "License for user $upn is OK"
            }
            else
            {
                $license = (Get-MsolAccountSku | where { ($_.activeUnits -ge 25) -or ($_.warningUnits -ge 25) }).accountSkuId
                Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses $license | Out-Null
                Write-Output "License added to user $upn"
            }
        }
        else
        {
            $Pass = Get-Content "D:\Credentials\Pass.txt"
            New-MsolUser -FirstName $first -LastName $last -UserPrincipalName $upn -Password $Pass -DisplayName $user -PasswordNeverExpires $true -ForceChangePassword $false | Out-Null
            Set-MsolUser -userprincipalname $upn -usagelocation RS | Out-Null
            $license = (Get-MsolAccountSku | where { ($_.activeUnits -ge 25) -or ($_.warningUnits -ge 25) }).accountSkuId
            Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses $license | Out-Null
            Write-Output "Created user: $upn"
        }
    }

    # Import Shared Mailboxes from CSV
    Write-Host "Importing Shared mailboxes" -ForegroundColor Cyan `n 
    
    $SharedMailboxes = Import-CSV -Path $CSVPath\SharedMailboxes.csv
    $SMCounter = $null # should reset the counter if script is run more than once in the same session
    $SharedMailboxes | ForEach-Object {
        $SMFullName = $_.Name
        $SMAlias = $_.Alias
        $SMTotalImports = $SharedMailboxes.count
        $SMCounter++
        $SMProgress = [int]($SMCounter / $SMTotalImports * 100)
                Write-Progress -Activity "Importing Shared mailboxes" -Status "Completed $SMCounter of $SMTotalImports" -PercentComplete $SMProgress
        if ( $SMFullName -like "* *" )
        {
            $SMSplitName = $SMFullName.Split(" ")
            $SMFirstName = $SMSplitName[0]
            $SMLastName = $SMSplitName[1]
            New-Mailbox -Shared -FirstName $SMFirstName -LastName $SMLastName -Name $SMFullName -Alias $SMAlias |
            Out-Null
        }
        else
        {
            New-Mailbox -Shared -Name $SMFullName -Alias $SMAlias |
            Out-Null
        }
    }

    # Report Number of imported items
    $SMTotalDestination = (Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox).count
    Write-Output "Imported $($SMTotalImports) items"
    Write-Output "Total number of Shared Mailboxes on Destination Server is $($SMTotalDestination)"

    
    # Import Equipment Mailboxes from CSV
    Write-Host "Importing Equipment Mailboxes" -ForegroundColor Cyan `n
    
    $Equipment = Import-CSV -Path $CSVPath\EquipmentMailboxes.csv
    $EQCounter = $null # should reset the counter if script is run more than once in the same session
    $Equipment | ForEach-Object {
        $EQAlias = $_.Alias
        $EQName = $_.Name
        $EQTotalImports = $Equipment.count
        $EQCounter++
        $EQProgress = [int]($EQCounter / $EQTotalImports * 100)
            Write-Progress -Activity "Importing Equipment Mailboxes" -Status "Completed $EQCounter of $EQTotalImports" -PercentComplete $EQProgress
            
            New-Mailbox -Equipment -Alias $EQAlias -Name $EQName -ResetPasswordOnNextLogon $false |
            Out-Null
    }
    
    # Report Number of imported items
    $EQTotalDestination = (Get-Mailbox -ResultSize unlimited -RecipientTypeDetails EquipmentMailbox).count
    Write-Output "Imported $($EQTotalImports) items"
    Write-Output "Total number of Equipment Mailboxes on Destination Server is $($EQTotalDestination)"
    
    # Import Room Mailboxes from CSV
    Write-Host "Importing Room Mailboxes" -ForegroundColor Cyan `n
    
    $Room = Import-CSV -Path $CSVPath\RoomMailboxes.csv
    $RMCounter = $null # should reset the counter if script is run more than once in the same session
    $Room | ForEach-Object {
        $RMAlias = $_.Alias
        $RMName = $_.Name
        $RMTotalImports = $Room.count
        $RMCounter++
        $RMProgress = [int]($RMCounter / $RMTotalImports * 100)
            Write-Progress -Activity "Importing Room Mailboxes" -Status "Completed $RMCounter of $RMTotalImports" -PercentComplete $RMProgress
            
            New-Mailbox -Room -Alias $RMAlias -Name $RMName  -ResetPasswordOnNextLogon $false |
            Out-Null
    }
    
    # Report Number of imported items
    $RMTotalDestination = (Get-Mailbox -ResultSize unlimited -RecipientTypeDetails RoomMailbox).count
    Write-Output "Imported $($RMTotalImports) items"
    Write-Output "Total number of Room Mailboxes on Destination Server is $($RMTotalDestination)"
}
else
{
    $ErrorText = "Domain must be in devcmpXX.onmicrosoft.com format.
    Your entry is: $fullDomain"
    Write-Host $ErrorText -ForegroundColor Red
    break
}