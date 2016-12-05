
function New-O365Destination_BK
{
    <#
        .SYNOPSIS
            Creates users and Public folder mailbox.
             
        .DESCRIPTION
            Creates 25 test users on the newly created domain, assigns them active licenses, and sets impersonation rights to Goran.Manot on the whole domain. 
            creates new Public Folder Mailbox and assings Owner permissions to Goran.Manot on root public folder.
    
        .EXAMPLE
            New-O365Destination_BK devcmp25
    
            Creates 25 users with @devcmp25.onmicrosoft.com domain
    #>

    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$true,
                   Position=1,
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$False)]
        [String]$domain 
    )
    $fullDomain = $domain + ".onmicrosoft.com"
    if ($fullDomain -like "devcmp*.onmicrosoft.com")
    {

        # connect to O365
        Write-Host "Connecting to O365" -ForegroundColor Cyan

        $UserCredential = Get-Credential
        
        Connect-MsolService
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
        
        Import-PSSession $Session
        
        # create an array of users which will be created
        $users = New-Object System.Collections.ArrayList
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
                Write-Host "User $upn already exists"
            }
            else
            {
                New-MsolUser -FirstName $first -LastName $last -UserPrincipalName $upn -Password m1cr0s0ft$ -DisplayName $user -PasswordNeverExpires $true -ForceChangePassword $false | Out-Null
                Set-MsolUser -userprincipalname $upn -usagelocation RS | Out-Null
                $tenant = (Get-MsolAccountSku).AccountObjectId
                Set-MsolUserLicense -TenantId $tenant -UserPrincipalName $upn -AddLicenses (Get-MsolAccountSku -TenantId $tenant).AccountSkuId | Out-Null
                Write-Output "Created user: $upn"
            }
        }

        # create public folder and add permissions to it
        Write-Host "Creating Public Folder Mailbox" -ForegroundColor Cyan

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
        $ErrorText = "Domain must be in devcmpXX.onmicrosoft.com format.
        Youre entry is: $fullDomain"
        Write-Host $ErrorText -ForegroundColor Red
        break
    }

    # apply impersonation rights for goran.manot user on whole domain
    Write-Host "Applying impersonation rights to Goran.Manot" -ForegroundColor Cyan

    Enable-OrganizationCustomization
    $User = "goran.manot" + "@" + $fullDomain
    New-ManagementRoleAssignment -Role ApplicationImpersonation -User $User | Out-Null
    Remove-PSSession $Session
}