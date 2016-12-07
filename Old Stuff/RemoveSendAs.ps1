$users = Import-CSV -Path C:\Scripts\Users.csv
$users | ForEach-Object {
$Identity = $_.Identity
$Trustee = $_.Trustee
Remove-RecipientPermission $Identity -AccessRights SendAs -Trustee $Trustee
}