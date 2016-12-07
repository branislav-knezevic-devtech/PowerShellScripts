#################
# SOURCE SERVER #
#################

#Create session to source
Write-Host `n
Write-Host "Connecting to Source Server" -ForegroundColor Cyan
Write-Host `n

$SourceServer = Read-Host -Prompt "Input your server name (e.g. mail.servername.com)"
$UserCredential = Get-Credential
$SourceServerFull = "https://" + $SourceServer + "/powershell"
$SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
$SessionSource = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $SourceServerFull -Authentication Basic -Credential $UserCredential –SessionOption $SessionOptions
Import-PSSession $SessionSource

#Create Directory for temporary CSV files
$TestScriptMigration = Test-Path C:\Temp\ScriptMigration
if($TestScriptMigration -eq $false)
    {
    New-Item -ItemType directory -Path C:\Temp\ScriptMigration |
        Out-Null
    }


#Create Directory for Report and log files
$TestScriptMigrationReport = Test-Path C:\Temp\ScriptMigrationReport
if($TestScriptMigrationReport -eq $false)
    {
    New-Item -ItemType directory -Path C:\Temp\ScriptMigrationReport |
        Out-Null
    }


#Export External contacts to csv
Write-Host `n
Write-Host "Exporting External contacs"
Write-Host `n
Get-MailContact -ResultSize unlimited | 
    Select Name, PrimarySmtpAddress,Alias |
    Export-Csv C:\Temp\ScriptMigration\MailContacts.csv

#Export Shared Mailboxes to csv
Write-Host `n
Write-Host "Exporting Shared mailboxes" 
Write-Host `n
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox | 
    Select Name, Alias, Identity | 
    Export-Csv C:\Temp\ScriptMigration\SharedMailboxes.csv

#Export Equipment Mailboxes to csv
Write-Host `n
Write-Host "Exporting Equipment Mailboxes" 
Write-Host `n
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails EquipmentMailbox | 
    Select Name, Alias |
    Export-Csv C:\Temp\ScriptMigration\EquipmentMailboxes.csv

#Export Room Mailboxes to csv
Write-Host `n
Write-Host "Exporting Room Mailboxes" 
Write-Host `n
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails RoomMailbox | 
    Select Name, Alias |
    Export-Csv C:\Temp\ScriptMigration\RoomMailboxes.csv

#End session on source
Write-Host `n
Write-Host "Disconnecting from Source Server" -ForegroundColor Cyan 
Write-Host `n

Remove-PSSession -Session $SessionSource


######################
# DESTINATION SERVER #
######################

#Create session to destination
Write-Host `n
Write-Host "Connecting to Destination Server" -ForegroundColor Cyan
Write-Host `n
$LiveCred = Get-Credential
$SessionDestination = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $SessionDestination

#Import Mail Contacts from CSV
Write-Host `n
Write-Host "Importing External contacs" 
Write-Host `n

$MailContacts = Import-CSV -Path C:\Temp\ScriptMigration\MailContacts.csv
$MCCounter = $null # should reset the counter if script is run more than once in the same session
$MailContacts | ForEach-Object {
    $MCFullName = $_.Name
    $MCSplitName = $MCFullName.Split(" ")
    $MCFirstName = $MCSplitName[0]
    $MCLastName = $MCSplitName[1]
    $MCEmail = $_.PrimarySmtpAddress
    $MCAlias = $_.Alias
    $MCTotalImports = $MailContacts.count
    $MCCounter++
    $MCProgress = [int]($MCCounter / $MCTotalImports * 100)
        Write-Progress -Activity "Importing Mail Contacts" -Status "Completed $MCCounter of $MCTotalImports" -PercentComplete $MCProgress
        
        New-MailContact -FirstName $MCFirstName -LastName $MCLastName -Alias $MCAlias -Name $MCFullName -ExternalEmailAddress $MCEmail |
        Out-Null
    }

#Report Number of imported items
$MCTotalDestination = (Get-MailContact -ResultSize unlimited).count
Write-Host "Imported $($MCTotalImports) items"
Write-Host "Total number of Mail Contacts on Destination Server is $($MCTotalDestination)"

#Import Shared Mailboxes from CSV
Write-Host `n
Write-Host "Importing Shared mailboxes" 
Write-Host `n

$SharedMailboxes = Import-CSV -Path D:\ScriptMigration\SharedMailboxes.csv
$SMCounter = $null # should reset the counter if script is run more than once in the same session
$SharedMailboxes | ForEach-Object {
    $SMFullName = $_.Name
    $SMAlias = $_.Alias
    $SMTotalImports = $SharedMailboxes.count
    $SMCounter++
    $SMProgress = [int]($SMCounter / $SMTotalImports * 100)
            Write-Progress -Activity "Importing Shared mailboxes" -Status "Completed $SMCounter of $SMTotalImports" -PercentComplete $SMProgress
    if ( $SMFullName -like "* *" )
    {
        $SMSplitName = $SMFullName.Split(" ")
        $SMFirstName = $SMSplitName[0]
        $SMLastName = $SMSplitName[1]
            
        New-Mailbox -Shared -FirstName $SMFirstName -LastName $SMLastName -Name $SMFullName -Alias $SMAlias |
        Out-Null
    }
    else
    {
        New-Mailbox -Shared -Name $SMFullName -Alias $SMAlias |
        Out-Null
    }
    }

#Report Number of imported items
$SMTotalDestination = (Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox).count
Write-Host "Imported $($SMTotalImports) items"
Write-Host "Total number of Shared Mailboxes on Destination Server is $($SMTotalDestination)"

#Import Equipment Mailboxes from CSV
Write-Host `n
Write-Host "Importing Equipment Mailboxes" 
Write-Host `n

$Equipment = Import-CSV -Path C:\Temp\ScriptMigration\EquipmentMailboxes.csv
$EQCounter = $null # should reset the counter if script is run more than once in the same session
$Equipment | ForEach-Object {
    $EQAlias = $_.Alias
    $EQName = $_.Name
    $EQTotalImports = $Equipment.count
    $EQCounter++
    $EQProgress = [int]($EQCounter / $EQTotalImports * 100)
        Write-Progress -Activity "Importing Equipment Mailboxes" -Status "Completed $EQCounter of $EQTotalImports" -PercentComplete $EQProgress
        
        New-Mailbox -Equipment -Alias $EQAlias -Name $EQName -ResetPasswordOnNextLogon $false |
        Out-Null
    }

#Report Number of imported items
$EQTotalDestination = (Get-Mailbox -ResultSize unlimited -RecipientTypeDetails EquipmentMailbox).count
Write-Host "Imported $($EQTotalImports) items"
Write-Host "Total number of Equipment Mailboxes on Destination Server is $($EQTotalDestination)"

#Import Room Mailboxes from CSV
Write-Host `n
Write-Host "Importing Room Mailboxes" 
Write-Host `n

$Room = Import-CSV -Path C:\Temp\ScriptMigration\RoomMailboxes.csv
$RMCounter = $null # should reset the counter if script is run more than once in the same session
$Room | ForEach-Object {
    $RMAlias = $_.Alias
    $RMName = $_.Name
    $RMTotalImports = $Room.count
    $RMCounter++
    $RMProgress = [int]($RMCounter / $RMTotalImports * 100)
        Write-Progress -Activity "Importing Room Mailboxes" -Status "Completed $RMCounter of $RMTotalImports" -PercentComplete $RMProgress
        
        New-Mailbox -Room -Alias $RMAlias -Name $RMName  -ResetPasswordOnNextLogon $false |
        Out-Null
    }

#Report Number of imported items
$RMTotalDestination = (Get-Mailbox -ResultSize unlimited -RecipientTypeDetails RoomMailbox).count
Write-Host "Imported $($RMTotalImports) items"
Write-Host "Total number of Room Mailboxes on Destination Server is $($RMTotalDestination)"


###################
# GENERATE REPORT #
###################

Write-Host `n "Generating Report..."

#Export External contacts to csv for report purposes
Get-MailContact -ResultSize unlimited | 
    Select Name, Alias, PrimarySmtpAddress |
    Export-Csv C:\Temp\ScriptMigrationReport\MailContacts.csv |
    Out-Null

#Export Shared Mailboxes to csv for report purposes
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox | 
    Select Name, Alias, PrimarySmtpAddress |
    Export-Csv C:\Temp\ScriptMigrationReport\SharedMailboxes.csv |
    Out-Null

#Export Equipment Mailboxes to csv for report purposes
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails EquipmentMailbox | 
    Select Name, Alias, PrimarySmtpAddress |
    Export-Csv C:\Temp\ScriptMigrationReport\EquipmentMailboxes.csv |
    Out-Null

#Export Room Mailboxes to csv for report purposes
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails RoomMailbox | 
    Select Name, Alias, PrimarySmtpAddress |
    Export-Csv C:\Temp\ScriptMigrationReport\RoomMailboxes.csv |
    Out-Null

#Sums the total number of imported items and number of items on destination server
$ReportDate = Get-Date
Write-Output "Report for Script migration done on $($ReportDate)" `n |
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append

Write-Output "Number of Imported Mail Contacts is $($MCTotalImports)" | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append
Write-Output "Total number of Mail Contacts on Destination Server is $($MCTotalDestination)" | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append

Write-Output "Number of Imported Shared Mailboxes is $($SMTotalImports)" | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append
Write-Output "Total number of Shared Mailboxes on Destination Server is $($SMTotalDestination)" | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append

Write-Output "Number of Imported Equipment Mailboxes is $($EQTotalImports)" | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append
Write-Output "Total number of Equipment Mailboxes on Destination Server is $($EQTotalDestination)" | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append

Write-Output "Number of Imported Room Mailboxes is $($RMTotalImports)" | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append
Write-Output "Total number of Room Mailboxes on Destination Server is $($RMTotalDestination)" `n `n | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append


#End session on destination
Write-Host `n
Write-Host "Disconnecting from Destination Server" -ForegroundColor Cyan 
Write-Host `n

Remove-PSSession -Session $SessionDestination

#Remove CSV Files
Remove-Item -Path C:\Temp\ScriptMigration -Force -Confirm:$false -Recurse


Write-Host `n
Write-Host "Migration of Mail Contacts, Shared and Resource mailboxes is now complete" -ForegroundColor Cyan
Write-Host `n
Write-Host "Reports for this migration are located at C:\Temp\ScriptMigrationReport folder" -ForegroundColor Cyan
Write-Host `n

Pause


<#
$Test = Test-Path C:\HyperV\$VMName
if($Test -eq $false)
    {
        New-Item C:\HyperV\$VMName -ItemType Directory
    }
#>