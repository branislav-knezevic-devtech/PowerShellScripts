#Create session to source
$UserCredential = Get-Credential
$SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
$SessionSource = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://mail.cloudmigrationservice.net/powershell -Authentication Basic -Credential $UserCredential –SessionOption $SessionOptions
Import-PSSession $SessionSource

#Export External contacts to csv
Get-MailContact -ResultSize unlimited | Export-Csv C:\Temp\ScriptTest\MailContacts.csv


#End session on source
Remove-PSSession -Session $SessionSource

#Create session to destination
$LiveCred = Get-Credential
$SessionDestination = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $SessionDestination

#Import External Contacts from CSV
$users = Import-CSV -Path C:\Temp\ScriptTest\MailContacts.csv
$users | ForEach-Object {
$FullName = $_.Name
$SplitName = $FullName.Split(" ")
$FirstName = $SplitName[0]
$LastName = $SplitName[1]
$Email = $_.PrimarySmtpAddress
$Alias = $_.Alias
New-MailContact -FirstName $FirstName -LastName $LastName -Alias $Alias -Name $FullName -ExternalEmailAddress $Email
}

#End session on destination
Remove-PSSession -Session $SessionDestination

