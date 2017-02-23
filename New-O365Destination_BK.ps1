
function New-O365Destination_BK
{
    <#
        .SYNOPSIS
            Creates users and Public folder mailbox.
             
        .DESCRIPTION
            Creates 25 test users on the newly created domain, assigns them active licenses, and sets impersonation rights to admin (GM) user on the whole domain.
            Imports Mail Contacts, Shared, Room and Equipment malboxes into the same destination.
            Creates new Public Folder Mailbox and assings Owner permissions to Goran.Manot on root public folder.
    
        .EXAMPLE
            New-O365Destination_BK 32
    
            Creates 25 users with @devcmp32.onmicrosoft.com domain. Check description for other details.
    #>

    [CmdletBinding()]
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
        $Password = Get-Content "D:\Credentials\Password.txt" | ConvertTo-SecureString
        $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $FullAdminName, $Password
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection -Name $fullDomain
        Import-PSSession $Session
        Connect-MsolService -Credential $Cred
        Write-Host "Session established to: $fullDomain" -ForegroundColor Green
        
        # create an array of users which will be created
        $users = New-Object System.Collections.ArrayList
        $users.Add("atila bala") | Out-Null
        $users.Add("nemanja tomic") | Out-Null
        $users.Add("fedor hajdu") | Out-Null
        $users.Add("milan stojanovic") | Out-Null
        $users.Add("slavisa radicevic") | Out-Null
        $users.Add("paula novokmet") | Out-Null
        $users.Add("robert sebescen") | Out-Null
        $users.Add("dragan eremic") | Out-Null
        $users.Add("vladimir pecanac") | Out-Null
        $users.Add("milivoj kovacevic") | Out-Null
        $users.Add("martin jonas") | Out-Null
        $users.Add("dragana berber") | Out-Null
        $users.Add("danijel avramov") | Out-Null
        $users.Add("dejan babic") | Out-Null
        $users.Add("Babara Harcharik") | Out-Null
        $users.Add("Brenton Byus") | Out-Null
        $users.Add("Catrice Hartz") | Out-Null
        $users.Add("Doris Luening") | Out-Null
        $users.Add("Ebony Tott") | Out-Null
        $users.Add("Florentino Snobeck") | Out-Null
        $users.Add("Ila Lockamy") | Out-Null
        $users.Add("Lovie Geronime") | Out-Null
        $users.Add("Lucretia Sangalli") | Out-Null
        $users.Add("Randell Fleniken") | Out-Null
        
        # Crate user account from users in the array
        Write-Host "Creating users on the destination" -ForegroundColor Cyan

        foreach ($user in $users) 
        {
            $u = New-Object System.Collections.ArrayList
            $u = $user.Split(" ")
            
            $first = $u[0]
            $last = $u[1]
            
            $upn = $first + "." + $last + "@" + $fullDomain

            if ( (Get-MsolUser).userprincipalname -like $upn )
            {
                Write-Output "User $upn already exists"
            }
            else
            {
                $pass = Get-Content D:\Credentials\Pass.txt
                New-MsolUser -FirstName $first -LastName $last -UserPrincipalName $upn -Password $Pass -DisplayName $user -PasswordNeverExpires $true -ForceChangePassword $false | Out-Null
                Set-MsolUser -userprincipalname $upn -usagelocation RS | Out-Null
                $tenant = (Get-MsolAccountSku).AccountObjectId
                Set-MsolUserLicense -TenantId $tenant -UserPrincipalName $upn -AddLicenses (Get-MsolAccountSku -TenantId $tenant).AccountSkuId | Out-Null
                Write-Output "Created user: $upn"
            }
        }

        # wait until other mailboxes actually exist on the destination
        DO
        {
            Get-Mailbox
            Start-Sleep -Seconds 10
        }
        until
        (
            (get-mailbox).count -gt 1
        )

        
        # Import data from CSV files
        $CSVPath = "D:\CSV_Data"
    
        # Import Shared Mailboxes from CSV
        Write-Host "Importing Shared mailboxes" `n
        
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
        Write-Host "Importing Equipment Mailboxes" `n
        
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
        Write-Host "Importing Room Mailboxes" `n
        
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


        # create public folder and add permissions to it
        
        Write-Host "Creating Public Folder Mailbox" -ForegroundColor Cyan

        if ( (Get-Mailbox -PublicFolder) -ne $null)
        {
            if ( (Get-Mailbox -PublicFolder).name -like "PublicFolderMailbox" )
            {
                Write-Host 'Public Folder Mailbox with name "PublicfolderMailbox" already exists' -ForegroundColor Yellow
            }
            else
            {
                New-Mailbox -Name PublicFolderMailbox -PublicFolder | Out-Null
                Add-PublicFolderClientPermission \ -User goran.manot -AccessRights owner | Out-Null
                $PFMailbox = (Get-Mailbox -publicfolder).name
                Write-Output "Public folder Mailbox: $PFMailbox has been created"
            }
        }
        else
        {
            New-Mailbox -Name PublicFolderMailbox -PublicFolder | Out-Null
            Add-PublicFolderClientPermission \ -User goran.manot -AccessRights owner | Out-Null
            $PFMailbox = (Get-Mailbox -publicfolder).name
            Write-Output "Public folder Mailbox: $PFMailbox has been created"
        }
        Set-OrganizationConfig -DefaultPublicFolderProhibitPostQuota 53687091200
        Set-OrganizationConfig -DefaultPublicFolderIssueWarningQuota 53687091200

        # apply impersonation rights for goran.manot user on whole domain
        Write-Host "Applying impersonation rights to Goran.Manot" -ForegroundColor Cyan

        Enable-OrganizationCustomization
        New-ManagementRoleAssignment -Role ApplicationImpersonation -User $FullAdminName | Out-Null

    }
    else
    {
        $ErrorText = "Domain must be in devcmpXX.onmicrosoft.com format.
        Your entry is: $fullDomain"
        Write-Host $ErrorText -ForegroundColor Red
        break
    }

   
    
}