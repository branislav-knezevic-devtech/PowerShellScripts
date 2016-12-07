#################
# SOURCE SERVER #
#################

#Create session to source
Write-Host " "
Write-Host "Connecting to Source Server"
Write-Host " "

$SourceServer = Read-Host -Prompt "Input your server name (e.g. mail.servername.com)"
$UserCredential = Get-Credential
#$SourceServer = "https://mail.cloudmigrationservice.net"
$SourceServerFull = "https://" + $SourceServer + "/powershell"
$SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
$SessionSource = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $SourceServerFull -Authentication Basic -Credential $UserCredential –SessionOption $SessionOptions
Import-PSSession $SessionSource

#Create Directory for temporary CSV files
New-Item -ItemType directory -Path C:\Temp\ScriptMigration |
    Out-Null

#Export External contacts to csv
Write-Host " "
Write-Host "Exporting External contacs"
Write-Host " "
Get-MailContact -ResultSize unlimited | 
    Select Name, PrimarySmtpAddress,Alias |
    Export-Csv C:\Temp\ScriptMigration\MailContacts.csv

#Export Shared Mailboxes to csv
Write-Host " "
Write-Host "Exporting Shared mailboxes" -ForegroundColor Cyan
Write-Host " "
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox | 
    Select Name, Alias |
    Export-Csv C:\Temp\ScriptMigration\SharedMailboxes.csv

#Export Equipment Mailboxes to csv
Write-Host " "
Write-Host "Exporting Equipment Mailboxes" -ForegroundColor Cyan
Write-Host " "
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails EquipmentMailbox | 
    Select Name, Alias |
    Export-Csv C:\Temp\ScriptMigration\EquipmentMailboxes.csv

#Export Room Mailboxes to csv
Write-Host " "
Write-Host "Exporting Room Mailboxes" -ForegroundColor Cyan
Write-Host " "
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails RoomMailbox | 
    Select Name, Alias |
    Export-Csv C:\Temp\ScriptMigration\RoomMailboxes.csv

#End session on source
Write-Host " "
Write-Host "Disconnecting from Source Server" -ForegroundColor Cyan 
Write-Host " "

Remove-PSSession -Session $SessionSource

######################
# DESTINATION SERVER #
######################


#Create session to destination
Write-Host " "
Write-Host "Connecting to Destination Server" -ForegroundColor Cyan
Write-Host " "
$LiveCred = Get-Credential
$SessionDestination = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $SessionDestination

#Import External Contacts from CSV
Write-Host " "
Write-Host "Importing Exporting External contacs" -ForegroundColor Cyan
Write-Host " "

$MailContacts = Import-CSV -Path C:\Temp\ScriptMigration\MailContacts.csv
$MailContacts | ForEach-Object {
    $MCFullName = $_.Name
    $MCSplitName = $MCFullName.Split(" ")
    $MCFirstName = $MCSplitName[0]
    $MCLastName = $MCSplitName[1]
    $MCEmail = $_.PrimarySmtpAddress
    $MCAlias = $_.Alias
        New-MailContact -FirstName $MCFirstName -LastName $MCLastName -Alias $MCAlias -Name $MCFullName -ExternalEmailAddress $MCEmail |
        Out-Null
    }

#Import Shared Mailboxes from CSV
Write-Host " "
Write-Host "Importing Shared mailboxes" -ForegroundColor Cyan
Write-Host " "

$SharedMailboxes = Import-CSV -Path C:\Temp\ScriptMigration\SharedMailboxes.csv
$SharedMailboxes | ForEach-Object {
    $SMFullName = $_.Name
    $SMSplitName = $SMFullName.Split(" ")
    $SMFirstName = $SMSplitName[0]
    $SMLastName = $SMSplitName[1]
    $SMAlias = $_.Alias
    New-Mailbox -Shared -FirstName $SMFirstName -LastName $SMLastName -Name $SMFullName -Alias $SMAlias |
        Out-Null
    }

#Import Equipment Mailboxes from CSV
Write-Host " "
Write-Host "Importing Equipment Mailboxes" -ForegroundColor Cyan
Write-Host " "

$Equipment = Import-CSV -Path C:\Temp\ScriptMigration\EquipmentMailboxes.csv
$Equipment | ForEach-Object {
    $EQAlias = $_.Alias
    $EQName = $_.Name
    New-Mailbox -Equipment -Alias $EQAlias -Name $EQName -ResetPasswordOnNextLogon $false |
        Out-Null
    }

#Import Room Mailboxes from CSV
Write-Host " "
Write-Host "Importing Room Mailboxes" -ForegroundColor Cyan
Write-Host " "

$Room = Import-CSV -Path C:\Temp\ScriptMigration\RoomMailboxes.csv
$Room | ForEach-Object {
    $RMAlias = $_.Alias
    $RMName = $_.Name
    New-Mailbox -Room -Alias $RMAlias -Name $RMName  -ResetPasswordOnNextLogon $false |
        Out-Null
    }

#End session on destination
Write-Host " "
Write-Host "Disconnecting from Destination Server" -ForegroundColor Cyan 
Write-Host " "

Remove-PSSession -Session $SessionDestination

#Remove CSV Files
Remove-Item -Path C:\Temp\ScriptMigration -Force -Confirm:$false -Recurse


Write-Host " "
Write-Host "Migration of Mail Contacts, Shared and Resource mailboxes is now complete" -ForegroundColor Cyan
Write-Host " "