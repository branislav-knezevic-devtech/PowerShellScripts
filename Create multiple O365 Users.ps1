$domain = "@devcmp20.onmicrosoft.com"
$UserCredential = Get-Credential

Connect-MsolService
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

Import-PSSession $Session


$users = New-Object System.Collections.ArrayList
#$users.Add("goran manot")
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
#$users.Add("vladimir kreko")
#$users.Add("milos tomasevic")
#$users.Add("filip uzunovic")
#$users.Add("milos mokic")
#$users.Add("snezana ralic")
#$users.Add("marko pap")
#$users.Add("mile misan")
#$users.Add("velibor glisin")
#$users.Add("vladislav herbut")
#$users.Add("ivica kolenkas")
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

foreach ($user in $users) {
$u = New-Object System.Collections.ArrayList
$u = $user.Split(" ")


$first = $u[0]
$last = $u[1]

$upn = $first + "." + $last + $domain

New-MsolUser -FirstName $first -LastName $last -UserPrincipalName $upn -Password m1cr0s0ft$ -DisplayName $user -PasswordNeverExpires $true -ForceChangePassword $false

set-msoluser -userprincipalname $upn -usagelocation RS

$tenant = (Get-MsolAccountSku).AccountObjectId
Set-MsolUserLicense -TenantId $tenant -UserPrincipalName $upn -AddLicenses (Get-MsolAccountSku -TenantId $tenant).AccountSkuId


}

Enable-OrganizationCustomization
$User = "goran.manot" + $domain
New-ManagementRoleAssignment -Role ApplicationImpersonation -User $User
#Disable-Organi
#>
Remove-PSSession $Session
