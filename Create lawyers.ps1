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

    $AdminName = "Administrator"
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

    # create an array of users which will be created
    $users = New-Object System.Collections.ArrayList
    $users.Add("Lawyer1") | Out-Null
    $users.Add("Lawyer2") | Out-Null
    $users.Add("Lawyer3") | Out-Null
    $users.Add("Lawyer4") | Out-Null
    $users.Add("Lawyer5") | Out-Null
       
    # Crate user account from users in the array
    Write-Host "Creating users on the destination" -ForegroundColor Cyan

    foreach ($user in $users) 
    {
        $upn = $user + "@" + $fullDomain

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
                $license = (Get-MsolAccountSku | where { ($_.activeUnits -eq 25) -or ($_.warningUnits -eq 25) }).accountSkuId
                Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses $license | Out-Null
                Write-Output "License added to user $upn"
            }
        }
        else
        {
            $Pass = Get-Content "D:\Credentials\Pass.txt"
            New-MsolUser -UserPrincipalName $upn -Password $Pass -DisplayName $user -PasswordNeverExpires $true -ForceChangePassword $false | Out-Null
            Set-MsolUser -userprincipalname $upn -usagelocation RS | Out-Null
            $license = (Get-MsolAccountSku | where { ($_.activeUnits -eq 25) -or ($_.warningUnits -eq 25) }).accountSkuId
            Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses $license | Out-Null
            Write-Output "Created user: $upn"
        }
    }
}
else
{
    $ErrorText = "Domain must be in devcmpXX.onmicrosoft.com format.
    Your entry is: $fullDomain"
    Write-Host $ErrorText -ForegroundColor Red
    break
}




$name = "Administrator"
$upn = $name + "@devcmp39.onmicrosoft.com"
$Pass = "Objection!" | ConvertTo-SecureString

New-Mailbox -Alias $name -DisplayName $name -PrimarySmtpAddress $name@devcmp30.onmicrosoft.com -Name $name


New-MsolUser -FirstName $name -UserPrincipalName $upn -DisplayName $name -PasswordNeverExpires $true -ForceChangePassword $false | Out-Null
Set-MsolUser -userprincipalname $upn -usagelocation RS | Out-Null
Set-MsolUser -userprincipalname $upn -pa
            