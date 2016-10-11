#################
# SOURCE SERVER #
#################

#Create session to source
Write-Host " "
Write-Host "Connecting to Source Server" -ForegroundColor Cyan
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

Write-Host "Exported $((Get-Mailcontact -ResultSize unlimited).count) Items"

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
Write-Host "Importing External contacs" 
Write-Host " "

$MailContacts = Import-CSV -Path C:\Temp\ScriptMigration\MailContacts.csv
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
