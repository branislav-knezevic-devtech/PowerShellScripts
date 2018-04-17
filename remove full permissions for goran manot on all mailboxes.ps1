$mbxs = Get-Mailbox 
foreach ($m in $mbxs)
{
    if ((Get-MailboxPermission $m.UserPrincipalName | where {$_.user -like "*goran.manot"}) -ne $null)
    {
        Remove-MailboxPermission -Identity $m.userprincipalname -User goran.manot -AccessRights fullaccess -Confirm:$false
        Write-Output "permissions removed from $($m.userprincipalname)"
    }
}

