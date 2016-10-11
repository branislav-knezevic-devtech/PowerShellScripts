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

#Export User Mailboxes to csv
Write-Host `n
Write-Host "Exporting User mailboxes" 
Write-Host `n
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails UserMailbox | 
    Select SamAccountName,OrganizationalUnit,Name,DisplayName | 
    Export-Csv C:\Temp\ScriptMigration\UserMailboxes.csv


#End session on source
Write-Host `n
Write-Host "Disconnecting from Source Server" -ForegroundColor Cyan 
Write-Host `n

Remove-PSSession -Session $SessionSource


######################
# DESTINATION SERVER #
######################

#Create session to destination
$DestinationServer = Read-Host -Prompt "Input your server name (e.g. mail.servername.com)"
$UserCredential = Get-Credential
$DestinationServerFull = "https://" + $DestinationServer + "/powershell"
$SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
$SessionDestination = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $DestinationServerFull -Authentication Basic -Credential $UserCredential –SessionOption $SessionOptions
Import-PSSession $SessionDestination


#Import Shared Mailboxes from CSV
Write-Host `n
Write-Host "Importing User mailboxes" 
Write-Host `n

$UserMailboxes = Import-CSV -Path C:\Temp\ScriptMigration\UserMailboxes.csv
$UserMailboxes | ForEach-Object {
    $UMFullName = $_.DisplayName
    $UMSplitName = $UMFullName.Split(" ")
    $UMFirstName = $UMSplitName[0]
    $UMLastName = $UMSplitName[1]
    $UMAlias = $_.SamAccountName
    $UMUserPrincipalName = $UMAlias + "@" + (Get-userPrincipalNamesSuffix)
    $UMOU = $_.OrganizationalUnit
    $UMPassword = ConvertTo-SecureString "m1cr0s0ft$" -AsPlainText -Force
    $UMTotalImports = $UserMailboxes.count
    $UMCounter++
    $UMProgress = [int]($UMCounter / $UMTotalImports * 100)
        Write-Progress -Activity "Importing User mailboxes" -Status "Completed $UMCounter of $UMTotalImports" -PercentComplete $UMProgress
        
        New-Mailbox -FirstName $UMFirstName -LastName $UMLastName -Name $UMFullName -Alias $UMAlias -UserPrincipalName $UMUserPrincipalName -OrganizationalUnit $UMOU -Password $UMPassword |
            Out-Null
    }

#Report Number of imported items
$UMTotalDestination = (Get-Mailbox -ResultSize unlimited -RecipientTypeDetails UserMailbox).count
Write-Host "Imported $($UMTotalImports) items"
Write-Host "Total number of User Mailboxes on Destination Server is $($UMTotalDestination)"

###################
# GENERATE REPORT #
###################

Write-Host "Generating Report..."

#Export User Mailboxes to csv for report purposes
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails UserMailbox | 
    Select Name, Alias, PrimarySmtpAddress |
    Export-Csv C:\Temp\ScriptMigrationReport\UserMailboxes.csv |
    Out-Null

#Sums the total number of imported items and number of items on destination server
$ReportDate = Get-Date
Write-Output "Report for Script migration done on $($ReportDate)" `n |
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append

Write-Output "Number of Imported User Mailboxes is $($UMTotalImports)" | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append
Write-Output "Total number of User Mailboxes on Destination Server is $($UMTotalDestination)" | 
    Out-File C:\Temp\ScriptMigrationReport\ImportedItemsLog.txt -Append

#End session on destination
Write-Host `n
Write-Host "Disconnecting from Destination Server" -ForegroundColor Cyan 
Write-Host `n

Remove-PSSession -Session $SessionDestination

#Remove CSV Files
#Remove-Item -Path C:\Temp\ScriptMigration -Force -Confirm:$false -Recurse


Write-Host `n
Write-Host "Migration of User mailboxes is now complete" -ForegroundColor Cyan
Write-Host `n
Write-Host "Reports for this migration are located at C:\Temp\ScriptMigrationReport folder" -ForegroundColor Cyan
Write-Host `n

Pause