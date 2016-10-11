Remove-DistributionGroup -Identity sales -Confirm:$false
Remove-DistributionGroup -Identity marketing -Confirm:$false
Remove-DistributionGroup -Identity finance -Confirm:$false
Remove-DistributionGroup -Identity it -Confirm:$false
Remove-DistributionGroup -Identity humanresources -Confirm:$false
Remove-DistributionGroup -Identity engineering -Confirm:$false
#Remove-DistributionGroup -Identity pemexchangeusers -Confirm:$false
Get-DistributionGroup

New-DistributionGroup -Alias engineering -Name engineering
New-DistributionGroup -Alias sales -Name sales
New-DistributionGroup -Alias marketing -Name marketing
New-DistributionGroup -Alias it -Name it
New-DistributionGroup -Alias finance -Name finance
New-DistributionGroup -Alias humanresources -Name humanresources
Get-DistributionGroup

Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox | Remove-Mailbox -Confirm:$False
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails RoomMailbox | Remove-Mailbox -Confirm:$False
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails EquipmentMailbox | Remove-Mailbox -Confirm:$False
Get-MailContact -ResultSize unlimited | Remove-MailContact -Confirm:$False
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox 
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails RoomMailbox 
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails EquipmentMailbox 
Get-MailContact -ResultSize unlimited 
