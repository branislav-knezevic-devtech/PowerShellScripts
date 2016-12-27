
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
        $Pass = Get-Content "D:\Credentials\Password.txt" | ConvertTo-SecureString
        $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $FullAdminName, $Pass
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection
        Import-PSSession $Session
        Connect-MsolService -Credential $Cred
        
        # create an array of users which will be created
        $users = New-Object System.Collections.ArrayList | Out-Null
        $users.Add("atila bala")
        $users.Add("nemanja tomic")
        $users.Add("fedor hajdu") 
        $users.Add("milan stojanovic") 
        $users.Add("slavisa radicevic") 
        $users.Add("paula novokmet") 
        $users.Add("robert sebescen") 
        $users.Add("dragan eremic") 
        $users.Add("vladimir pecanac") 
        $users.Add("milivoj kovacevic") 
        $users.Add("martin jonas") 
        $users.Add("dragana berber") 
        $users.Add("danijel avramov") 
        $users.Add("dejan babic") 
        $users.Add("Babara Harcharik") 
        $users.Add("Brenton Byus") 
        $users.Add("Catrice Hartz") 
        $users.Add("Doris Luening") 
        $users.Add("Ebony Tott") 
        $users.Add("Florentino Snobeck") 
        $users.Add("Ila Lockamy") 
        $users.Add("Lovie Geronime") 
        $users.Add("Lucretia Sangalli") 
        $users.Add("Randell Fleniken") 
        
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
            Start-Sleep -Seconds 30
        }
        until
        (
            (get-mailbox).count -gt 1
        )

        
        # Import data from CSV files
        $CSVPath = "D:\CSV_Data"

        # Import Mail Contacts 
        Write-Host "Importing External contacs" `n
        
        $MailContacts = Import-CSV -Path $CSVPath\MailContacts.csv
        $MCCounter = $null # should reset the counter if script is run more than once in the same session
        $MailContacts | ForEach-Object {
            $MCFullName = $_.Name
            $MCSplitName = $MCFullName.Split(" ")
            $MCFirstName = $MCSplitName[0]
            $MCLastName = $MCSplitName[1]
            $MCEmail = $_.PrimarySmtpAddress
            $MCAlias = $_.Alias
            $MCTotalImports = $MailContacts.count
            $MCCounter++
            $MCProgress = [int]($MCCounter / $MCTotalImports * 100)
                Write-Progress -Activity "Importing Mail Contacts" -Status "Completed $MCCounter of $MCTotalImports" -PercentComplete $MCProgress
                
                New-MailContact -FirstName $MCFirstName -LastName $MCLastName -Alias $MCAlias -Name $MCFullName -ExternalEmailAddress $MCEmail |
                Out-Null
        }
        
        # Report Number of imported items
        $MCTotalDestination = (Get-MailContact -ResultSize unlimited).count
        Write-Output "Imported $($MCTotalImports) items"
        Write-Output "Total number of Mail Contacts on Destination Server is $($MCTotalDestination)"

    
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

        if ( (Get-Mailbox -PublicFolder) -eq $null)
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
        Set-OrganizationConfig -DefaultPublicFolderProhibitPostQuota 10737418240
        Set-OrganizationConfig -DefaultPublicFolderIssueWarningQuota 9663676416

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