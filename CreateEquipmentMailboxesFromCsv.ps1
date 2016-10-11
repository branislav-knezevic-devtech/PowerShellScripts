$Equipment = Import-CSV -Path C:\Scripts\CSV\Equipment.csv
$Equipment | ForEach-Object {
$Object = $_.Equipment
New-Mailbox -Alias $Object -Name $Object -Equipment -ResetPasswordOnNextLogon $false -OrganizationalUnit "demouk.local/Equipment"
}
#Creates Equipment mailboxes from selected CSV and places them in desired OU