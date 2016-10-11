$mailboxes = @(Get-Mailbox -ResultSize Unlimited)
$report = @()

foreach ($mailbox in $mailboxes)
{
    Get-MailboxFolderStatistics $mailbox | ft Identity,Name,FolderSize,ItemsInFolder -AutoSize | Out-String -Width 4096

    
}

$report
#For different view, part after ItemsInFolder can be deleted