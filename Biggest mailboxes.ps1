# get biggest mailboxes by size and dipslay size in MB
# must be ran on the server directly

$Mailboxes = Get-Mailbox -RecipientTypeDetails usermailbox
foreach ($Mailbox in $Mailboxes)
{
    $Mailbox | Add-Member -MemberType “NoteProperty” -Name “MailboxSizeMB” -Value ((Get-MailboxStatistics $Mailbox).TotalItemSize.Value.ToMb())
}
$Mailboxes | Sort-Object MailboxSizeMB -Desc | Select PrimarySMTPAddress, MailboxSizeMB -First 25 | ft -AutoSize 