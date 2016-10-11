$FirstNames = Get-Content .\Names\FirstName.csv
$LastNames = Get-Content .\Names\LastName.csv
$UsersToCreate = 10
$Password = ConvertTo-SecureString "Control2000" -AsPlainText -Force
$OU = "demouk.local/BK-test"
$Departments = "Finance","IT","Marketing","Engineering","Sales","Human Resources"
$UPNSuffix = "demouk.local"
foreach ($Department in $Departments)
{
    New-DistributionGroup -Name $Department -OrganizationalUnit $OU 
}
for ($i=0; $i -lt $UsersToCreate; $i++)
{
    $FirstName = $FirstNames[(Get-Random -Minimum 0 -Maximum ($FirstNames.Count-1))]
    $LastName = $LastNames[(Get-Random -Minimum 0 -Maximum ($LastNames.Count-1))]
    $Username = "$($Firstname).$($LastName)"
    $DisplayName = "$($Firstname) $($LastName)"
    $Department = $Departments[(Get-Random -Minimum 0 -Maximum ($Departments.Count-1))]
    New-Mailbox -Name $DisplayName -SamAccountName $Username -UserPrincipalName "$($Username)@$($UPNSuffix)" -Alias $Username  -OrganizationalUnit $OU -Password $Password -FirstName $FirstName -LastName $LastName
    Set-User -Identity $Username -Department $Department
    Add-DistributionGroupMember -Identity $Department -Member $Username
} 
