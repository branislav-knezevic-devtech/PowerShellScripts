<#
    .SYNOPSIS
        Cleanes specified office 365 mailbox
         
    .DESCRIPTION
        If previously connected to the destination, cleanes the specifed mailboxes
        
    .EXAMPLE
        .\Clean-SingleUser.ps1
        Enter the username of user whose mailbox needs to be cleanned, e.g. Atila.Bala: dejan.babic
    
        Cleanes mailbox for user Dejan Babic
#>


# Prompt for user which is going to be removed
$CleanUser = Read-Host "Enter the username of user whose mailbox needs to be cleanned, e.g. Atila.Bala"
$domain = (Get-Mailbox -Identity goran.manot).userPrincipalName
$splitDomain = $domain.split("@")
$fullDomain = $splitDomain[1]
$CleanUserUPN = $CleanUser + "@" + $fullDomain

# check if user exists
if ((Get-MsolUser).userprincipalname -contains $CleanUserUPN)
{
    # Remove user
    Write-Host "Removing user $CleanUser" -ForegroundColor Cyan
    
    Remove-MsolUser -UserPrincipalName $CleanUserUPN -Force | Out-Null
    Remove-MsolUser -UserPrincipalName $CleanUserUPN -RemoveFromRecycleBin -Force | Out-Null
    
    do 
    {
        Start-Sleep -Seconds 5
    }
    until ((Get-MsolUser).userprincipalname -notcontains $CleanUserUPN)
    
    Write-Output "User $CleanUser removed"
    
    Start-Sleep -Seconds 20
    
    # Create user
    Write-Host "Creating user $CleanUser" -ForegroundColor Cyan
    $split = $CleanUser.Split(".")
    $first = $split[0]
    $last = $split[1]
    $dispName = $first + " " + $last
    $Pass = Get-Content "D:\Credentials\Pass.txt"
    
    New-MsolUser -FirstName $first -LastName $last -UserPrincipalName $CleanUserUPN -Password $Pass -DisplayName $dispName -PasswordNeverExpires $true -ForceChangePassword $false | Out-Null
    Set-MsolUser -userprincipalname $CleanUserUPN -usagelocation RS | Out-Null
    $license = (Get-MsolAccountSku | where { ($_.activeUnits -eq 25) -or ($_.warningUnits -eq 25) }).accountSkuId
    Set-MsolUserLicense -UserPrincipalName $CleanUserUPN -AddLicenses $license | Out-Null
    
    do 
    {
        Start-Sleep -Seconds 5
    }
    until ((Get-MsolUser -UserPrincipalName $CleanUserUPN) -ne $null)
    
    Write-Output "Created user: $CleanUserUPN"
    Write-Host "Plese wait 5-10 minutes after this cleanup before you try any new migrations" -ForegroundColor Cyan
}
else
{
    Write-Host "User $CleanUserUPN does not exist" -ForegroundColor Red
}



