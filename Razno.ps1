Get-Mailbox -Identity atila.bala | (Get-MailboxStatistics -Identity atila.bala).containerclass
$user = atila.bala
$Files1 = (Get-MailboxStatistics -Identity atila.bala).containerclass
$Files1
Get-Mailbox -Identity atila.bala | $Files1


Get-MailContact -ResultSize unlimited | Remove-MailContact
Get-Mailbox -ResultSize unlimited -RecipientTypeDetails EquipmentMailbox | Export-Csv C:\Temp\ScriptTest\EquipmentMailboxes.csv
 > C:\Temp\Equipment.txt
Get-Mailbox -Identity ime.prezime | Export-Csv C:\Temp\ScriptTest\imePrezime.csv
New-Mailbox -Shared -FirstName Ime -LastName Prezime -Name "Ime Prezime" -DisplayName "Ime Prezime" -Alias ime.prezime -PrimarySmtpAddress ime.prezime@cloudmigrationservice.net
Get-Mailbox -Identity deathstar

Get-MailContact -ResultSize unlimited | Remove-MailContact
Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize unlimited | Remove-Mailbox
Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize unlimited | Remove-Mailbox 
Get-Mailbox -RecipientTypeDetails EquipmentMailbox -ResultSize unlimited | Remove-Mailbox
Get-DistributionGroup -ResultSize unlimited | Export-Csv C:\Temp\ScriptTest\DistGroup.csv



        #test if petlje

$Number = 10
if ($Number -gt 0) {"Bigger than zero"}
$DG1 = "Security"
if ($DG1 -eq "Universal") {"Distribution"} Else {"Security"}

        #test switch petlje

$a = 5
Switch ($a)
    {
        1 {"The color is red."} 
        2 {"The color is blue."} 
        3 {"The color is green."} 
        4 {"The color is yellow."} 
        5 {"The color is orange."} 
    }

        #    {
    #        Open {"Open"}
    #        Closed {"Closed"}
    #        ApprovalRequired {"ApprovalRequired"}
    #    }
    #$DGMemberJoinRestriction = if ($_.MemberJoinRestriction -eq "TRUE") {
    #    $True
    #    } Else {
    #    $False
    #    }





