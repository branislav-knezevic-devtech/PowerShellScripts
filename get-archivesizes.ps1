$Office365Credentials = Get-Credential
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell/" -Credential $Office365Credentials -Authentication Basic -AllowRedirection
Import-PSSession $session
 
Write-Host "Gathering Stats, Please Wait.."
 
$Mailboxes = Get-Mailbox -ResultSize Unlimited | Select UserPrincipalName, identity, ArchiveStatus
 
$MailboxSizes = @()
 
foreach ($Mailbox in $Mailboxes) {
 
                $ObjProperties = New-Object PSObject
               
                $MailboxStats = Get-MailboxStatistics $Mailbox.UserPrincipalname | Select LastLogonTime, TotalItemSize, ItemCount
               
                Add-Member -InputObject $ObjProperties -MemberType NoteProperty -Name "UserPrincipalName" -Value $Mailbox.UserPrincipalName
                Add-Member -InputObject $ObjProperties -MemberType NoteProperty -Name "Last Logged In" -Value $MailboxStats.LastLogonTime
                Add-Member -InputObject $ObjProperties -MemberType NoteProperty -Name "Mailbox Size" -Value $MailboxStats.TotalItemSize
                Add-Member -InputObject $ObjProperties -MemberType NoteProperty -Name "Mailbox Item Count" -Value $MailboxStats.ItemCount
               
                if ($Mailbox.ArchiveStatus -eq "Active") {
               
                                $ArchiveStats = Get-MailboxStatistics $Mailbox.UserPrincipalname -Archive | Select TotalItemSize, ItemCount
                               
                                Add-Member -InputObject $ObjProperties -MemberType NoteProperty -Name "Archive Size" -Value $ArchiveStats.TotalItemSize
                                Add-Member -InputObject $ObjProperties -MemberType NoteProperty -Name "Archive Item Count" -Value $ArchiveStats.ItemCount
 
                }
                else {
               
                                Add-Member -InputObject $ObjProperties -MemberType NoteProperty -Name "Archive Size" -Value "No Archive"
                                Add-Member -InputObject $ObjProperties -MemberType NoteProperty -Name "Archive Item Count" -Value "No Archive"
                               
                }
               
                $MailboxSizes += $ObjProperties
 
}             
               
$MailboxSizes | Out-GridView -Title "Mailbox and Archive Sizes"
 
Get-PSSession | Remove-PSSession