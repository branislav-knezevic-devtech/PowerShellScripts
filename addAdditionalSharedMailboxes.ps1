$CSVPath = "D:\CSV_Data"

# Import Shared Mailboxes from CSV
Write-Host "Importing additional Shared mailboxes" `n

$SharedMailboxes = Import-CSV -Path $CSVPath\shared-expanded1.csv
$SMCounter = $null # should reset the counter if script is run more than once in the same session
$SharedMailboxes | ForEach-Object {
    $SMFullName = $_.Alias
    $SMAlias = $_.Alias
    $SMTotalImports = $SharedMailboxes.count
    $SMCounter++
    $SMProgress = [int]($SMCounter / $SMTotalImports * 100)
    Write-Progress -Activity "Importing Shared mailboxes" -Status "Completed $SMCounter of $SMTotalImports" -PercentComplete $SMProgress
    New-Mailbox -Shared -Name $SMFullName -Alias $SMAlias | Out-Null
}
    
# Report Number of imported items
$SMTotalDestination = (Get-Mailbox -RecipientTypeDetails SharedMailbox).count
Write-Output "Imported $($SMTotalImports) items"
Write-Output "Total number of Shared Mailboxes on Destination Server is $($SMTotalDestination)"

# set size quota for all mailboxes
    Get-Mailbox | Set-Mailbox -MaxReceiveSize 1mb -MaxSendSize 1mb

Get-Mailbox -RecipientTypeDetails usermailbox | Get-MailboxStatistics | ft displayname,totalitem*