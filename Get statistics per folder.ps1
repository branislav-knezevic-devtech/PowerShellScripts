Get-Mailbox atila.bala | Get-MailboxFolderStatistics | where {$_.itemsinfolder -gt 0} | select Name,FolderPath,ItemsInFolder
Get-Mailbox martin.jonas | Get-MailboxFolderStatistics -Archive | where {$_.name -eq "journal"} | select Name,FolderPath,ItemsInFolder
