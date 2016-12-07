$users = Import-CSV -Path C:\Scripts\Users.csv
$users | ForEach-Object {
$Identity = $_.Identity
$Trustee = $_.Trustee
Add-MailboxPermission $Trustee -User $Identity -AccessRights FullAccess
}