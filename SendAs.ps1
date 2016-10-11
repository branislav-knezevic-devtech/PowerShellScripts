$users = Import-CSV -Path C:\Scripts\Users.csv
$users | ForEach-Object {
$Identity = $_.Identity
$Trustee = $_.Trustee
Add-RecipientPermission $Identity -AccessRights SendAs -Trustee $Trustee
}