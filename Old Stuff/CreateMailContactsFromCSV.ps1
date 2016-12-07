$users = Import-CSV -Path C:\Scripts\Mail.contacts.csv
$users | ForEach-Object {
$FirstName = $_.first_name
$LastName = $_.last_name
$Email = $_.email
$FullName = $FirstName + " " + $LastName
$Alias1 = $FirstName + "." + $LastName
New-MailContact -FirstName $FirstName -LastName $LastName -Alias $alias1 -Name $FullName -ExternalEmailAddress $Email
#Add-MailboxPermission $Trustee -User $Identity -AccessRights FullAccess
}