############

# Auto sending of emails, specify number of emails in $emailsToSend
# Start-Sleep -Seconds 10800
$mailboxes = (Get-Mailbox -RecipientTypeDetails usermailbox -Database LargeScale).primarysmtpaddress
$word = Import-Csv -Path D:\CSV_Data\subject.csv
$text = Import-Csv -Path D:\CSV_Data\EmailBody.csv

$emailsToSend = 30000

for ($i=1; $i -le $emailsToSend; $i++)
{
    $to = $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))],`
          $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))],`
          $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))],`
          $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))],`
          $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))]
    $from = $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))]
    $body = $text[(Get-Random -Minimum 0 -Maximum ($text.Count-1))]
    $subject = $word[(Get-Random -Minimum 0 -Maximum ($word.Count-1))]
    Send-MailMessage -From $from -To $to -Subject $subject.Body -Body $body.Body -SmtpServer hex2016.devtech-labs.com -BodyAsHtml | Out-Null
    Write-Host "$i Email sent to $to"
}
###########################

$subject.Body

##########################

# Email sending on O365

# Assign SendAs permissions to sender:
$mailboxes = (Get-Mailbox -RecipientTypeDetails usermailbox |
              where {($_.userprincipalname -like "dragan.eremic*") -or `
                     ($_.userprincipalname -like "milivoj.kovacevic*") -or `
                     ($_.userprincipalname -like "dragana.berber*") -or `
                     ($_.userprincipalname -like "florentino.snobeck*") -or `
                     ($_.userprincipalname -like "babara.harcharik*")}).primarysmtpaddress
$sender = "goran.manot@devcmp47.onmicrosoft.com"
forEach ($m in $mailboxes)
{
    Add-RecipientPermission $m -AccessRights SendAs -Trustee $sender
}

# Authenticate to O365 
$FullAdminName = "goran.manot@devcmp47.onmicrosoft.com"
$Password = Get-Content "D:\Credentials\Password.txt" | ConvertTo-SecureString
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $FullAdminName, $Password
# Or authenticate via $credential = Get-Credential

# Send emails
$mailboxes = (Get-Mailbox -RecipientTypeDetails usermailbox |
              where {($_.userprincipalname -like "dragan.eremic*") -or `
                     ($_.userprincipalname -like "milivoj.kovacevic*") -or `
                     ($_.userprincipalname -like "dragana.berber*") -or `
                     ($_.userprincipalname -like "florentino.snobeck*") -or `
                     ($_.userprincipalname -like "babara.harcharik*")}).primarysmtpaddress
$sender = "goran.manot@devcmp47.onmicrosoft.com"
$word = Import-Csv -Path E:\CSV_Data\subject.csv
$text = Import-Csv -Path E:\CSV_Data\EmailBody.csv

$emailsToSend = 3000

for ($i=1; $i -le $emailsToSend; $i++)
{
    $to = $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))],`
          $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))],`
          $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))],`
          $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))],`
          $mailboxes[(Get-Random -Minimum 0 -Maximum ($mailboxes.Count-1))]
    $from = $senders #[(Get-Random -Minimum 0 -Maximum ($senders.Count-1))]
    $body = $text[(Get-Random -Minimum 0 -Maximum ($text.Count-1))]
    $subject = $word[(Get-Random -Minimum 0 -Maximum ($word.Count-1))]
    Send-MailMessage -From $from -To $to -Subject $subject.Body -Body $body.Body -SmtpServer smtp.office365.com -BodyAsHtml -Port 587 -Credential $cred -UseSsl | Out-Null
    # Start-Sleep -Seconds 3
    Write-Host "$i Email sent to $to"
}
##

# manual test
Send-MailMessage -From goran.manot@devcmp47.onmicrosoft.com -to martin.jonas@devcmp47.onmicrosoft.com -Subject "radi li?" -Body "Valjda radi" -SmtpServer smtp.office365.com -Port 587 -Credential $cred -UseSsl


##########################


# remove bunch of mailboxes with specified smtp address
$remove = Get-Mailbox -Database LargeScale | where {$_.primarysmtpaddress -like "sharedmailbox9*"}
ForEach ($r in $remove)
{
    Remove-Mailbox -Identity ($r).primarysmtpaddress -Force -Confirm:$false
}

# remove and then add specific sharedmailbox
Remove-Mailbox -Identity sharedMailbox48 -Force -Confirm:$false

$mailboxesToCreate = 10

for ($i=50; $i -le $mailboxesToCreate; $i++)
{
    $mailboxName = "SharedMailbox59"
    $password = "m1cr0s0ft$"
    $securePass = ConvertTo-SecureString -a -f $password
    $upn = $mailboxName + "@hex2016.devtech-labs.com"
    New-Mailbox -Name $mailboxName -Alias $mailboxName -Database LargeScale -OrganizationalUnit "cmp2016.local/cmp2016/LargeScale" -UserPrincipalName $upn -Password $securePass

}

####
Get-Mailbox -RecipientTypeDetails usermailbox -Database LargeScale | Get-MailboxStatistics  | select displayname,totalitemsize,itemcount
| where {$_.itemcount -le 1000}

(get-mailboxdatabase) | foreach-object {write-host $_.name (get-mailbox -database $_.name).count}