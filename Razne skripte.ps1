# remove 50 random user mailboxes from mailboxdatabase 2

$mailboxes = Get-Mailbox -Database mailboxdatabase2 -RecipientTypeDetails usermailbox
$randomMailboxes = Get-Random -inputobject $mailboxes -Count 50
foreach ($mbx in $randomMailboxes)
{
    Remove-Mailbox -Identity $mbx.identity -Confirm:$false
}


# purge those mailboxes from the database
Get-MailboxStatistics –Database mailboxdatabase2 | 
    where {$_.DisconnectReason –eq "SoftDeleted"} | 
    foreach {Remove-StoreMailbox –Database $_.database –Identity $_.mailboxguid –MailboxState SoftDeleted}


# remove full access on all shared mailboxes 
$mbxs = Get-Mailbox -RecipientTypeDetails sharedmailbox
foreach ($mbx in $mbxs)
{
    Remove-MailboxPermission -Identity $mbx.identity -User martin.jonas -AccessRights fullaccess -Confirm:$false | Out-Null
    Write-Output "mailbox permissions removed from $mbx"
}


# get public folder statistics per public folder. 
$PFs = Get-PublicFolder "\cppgateway.com public folders" -Recurse | where { $_.parentpath -notlike "\"}
foreach ($PF in $PFs)
{
    $pfName = $PF.parentpath + "\" + $PF.name
    $GetPF = Get-PublicFolder $pfName
    $getPFStat = Get-PublicFolderStatistics $pfName
    $sizeGB = $GetPF.FolderSize / 1GB
    $result = @{Name = $GetPF.name
                Path = $GetPF.parentpath
                ItemCount = $getPFStat.itemcount
                Size = $GetPF.foldersize
                SizeGB = $sizeGB}
    Write-Output $result `n | Out-File C:\Temp\PublicFolders19.txt -Append
} 

