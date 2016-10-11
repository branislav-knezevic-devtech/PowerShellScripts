$users = Import-CSV -Path C:\Scripts\ChangePrimarySMTP.csv
$users | ForEach-Object {
$Identity = $_.Identity
$NewPrimary = $_.NewPrimary
Set-Mailbox $Identity -EmailAddresses SMTP:$NewPrimary,$Identity
}