$domain = "@devcmp9.onmicrosoft.com"
$UserCredential = Get-Credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

Import-PSSession $Session

Connect-MsolService -Credential $UserCredential
$users = Import-CSV -Path C:\Scripts\UsersDelCre.csv
$users | ForEach-Object {
$Identity = $_.Identity
Remove-MsolUser -UserPrincipalName $Identity
#Remove-Mailbox -Identity $Identity 
}

#$NewUser = New-Object System.Collections.ArrayList
#
#$NewUser | ForEach-Object {
#$FullName = $_.FullName
#$NewUser.Add($FullName)
#
#
#foreach ($user in $NewUser) {
#$u = New-Object System.Collections.ArrayList
#$u = $user.Split(" ")
#
#
#$first = $u[0]
#$last = $u[1]
#
#$upn = $first + "." + $last + $domain 

$Users | ForEach-Object { 
$first = $_.FistName
$Last = $_.LastName
$Identity = $_.Identity
$DisplayName = $first + " " + $Last
New-MsolUser -UserPrincipalName $Identity -FirstName $first -LastName $last -Password m1cr0s0ft$ -DisplayName $DisplayName -usagelocation RS -PasswordNeverExpires $true -ForceChangePassword $false
}
#set-msoluser -userprincipalname $Identity 

$tenant = (Get-MsolAccountSku).AccountObjectId
Set-MsolUserLicense -TenantId $tenant -UserPrincipalName $Identity -AddLicenses (Get-MsolAccountSku -TenantId $tenant).AccountSkuId


}
Remove-PSSession $Session

$Users | ForEach-Object { 
$first = $_.FistName
$Last = $_.LastName
$Identity = $_.Identity
$DisplayName = $first + " " + $Last
$tenant = (Get-MsolAccountSku).AccountObjectId
New-MsolUser -UserPrincipalName $Identity -FirstName $first -LastName $last -Password m1cr0s0ft$ -DisplayName $DisplayName -usagelocation RS -PasswordNeverExpires $true -ForceChangePassword $false

#set-msoluser -userprincipalname $Identity 

$tenant = (Get-MsolAccountSku).AccountObjectId
Set-MsolUserLicense -TenantId $tenant -UserPrincipalName $Identity -AddLicenses (Get-MsolAccountSku -TenantId $tenant).AccountSkuId


}
