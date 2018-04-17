
$mailboxesToCreate = 200

for ($i=13; $i -le $mailboxesToCreate; $i++)
{
    $mailboxName = "SharedMailbox" + $i
    New-Mailbox -Shared -Name $mailboxName -Alias $mailboxName 
}


$mailboxesToCreate = 50

for ($i=1; $i -le $mailboxesToCreate; $i++)
{
    $mailboxName = "EquipmentMailbox" + $i
    New-Mailbox -Equipment -Alias $mailboxName -Name $mailboxName -ResetPasswordOnNextLogon $false
}



$mailboxesToCreate = 50

for ($i=1; $i -le $mailboxesToCreate; $i++)
{
    $mailboxName = "RoomMailbox" + $i
    New-Mailbox -Room -Alias $mailboxName -Name $mailboxName -ResetPasswordOnNextLogon $false
}

# set size quota for all mailboxes
    Get-Mailbox | Set-Mailbox -MaxReceiveSize 1mb -MaxSendSize 1mb
