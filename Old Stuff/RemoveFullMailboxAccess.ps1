$users = Import-CSV -Path C:\Scripts\Users.csv
$users | ForEach-Object {
$Identity = $_.Identity
$Trustee = $_.Trustee
Remove-MailboxPermission $Identity -User $Trustee -AccessRights FullAccess
}