<#
    Set existing script to limit all mailboxes to 1 MB
    Create Mailbox with items which have 2 MB attachment
    In Different Mailbox create items with 4MB, with characteristic name
    Export to PST
    Create Script to clean 4mb items from the mailbox
        Search-Mailbox might be usefull, needs to be tested
#>

# these work:
  # Contact
    Get-Mailbox -Identity sharedmailbox50 | Search-Mailbox -SearchQuery 'Kind:contacts and "petar petrovic"' -EstimateResultOnly # -DeleteContent -Confirm:$false -Force
  # Email
    Get-Mailbox -Identity sharedmailbox50 | Search-Mailbox -SearchQuery 'Subject: Pelican, australian' -DeleteContent -Confirm:$false -Force
  # Task
    Get-Mailbox -Identity sharedmailbox50 | Search-Mailbox -SearchQuery "Subject:Up-sized bottom-line architecture" -DeleteContent -Confirm:$false -Force
  # Calendar item
    Get-Mailbox -Identity goran.manot | Search-Mailbox -SearchQuery 'Kind:meetings and "content-based"' -EstimateResultOnly # -DeleteContent -Confirm:$false -Force

#--------------------------------
Get-Mailbox -RecipientTypeDetails usermailbox | Add-MailboxPermission -User goran.manot -AccessRights fullaccess -InheritanceType all -AutoMapping $false
Search-Mailbox <Source Mailbox> -SearchQuery attachment:"<Attachment file name>"

Get-Mailbox -Identity sharedmailbox50 | Search-Mailbox -SearchQuery "Subject: Arctic hare" -EstimateResultOnly #-TargetMailbox "DiscoverySearchMailbox {D919BA05-46A6-415f-80AD-7E09334BB852}" -TargetFolder SearchResults
Get-Mailbox -Identity sharedmailbox50 | Search-Mailbox -SearchQuery 'Subject: 11Event11' -LogOnly -LogLevel full -TargetMailbox "DiscoverySearchMailbox {D919BA05-46A6-415f-80AD-7E09334BB852}" -TargetFolder SearchResults
Get-Mailbox -Identity sharedmailbox50 | Search-Mailbox -SearchQuery 'Kind:meetings' -LogOnly -LogLevel full -TargetMailbox "DiscoverySearchMailbox {D919BA05-46A6-415f-80AD-7E09334BB852}" -TargetFolder SearchResults
Get-Mailbox -Identity sharedmailbox50 | Search-Mailbox -SearchQuery 'Kind:meetings AND "Subject:22Event22"' -DeleteContent -Confirm:$false -Force
Get-Mailbox -Identity sharedmailbox50 | Search-Mailbox -SearchQuery "Subject:22Event22" -DeleteContent -Confirm:$false -Force
Get-Mailbox -Identity goran.manot | Search-Mailbox -SearchQuery 'Kind:meetings and "utilisation"' -EstimateResultOnly
Get-Mailbox -Identity goran.manot | Search-Mailbox -SearchQuery 'Kind:meetings and "*Calendar*"' -EstimateResultOnly


(Get-ManagementRoleAssignment).name
Get-RoleGroup -Identity "discovery management"
Get-RoleGroupMember -Identity "discovery management"
Remove-RoleGroupMember -Identity "discovery management" -Member goran.manot -Confirm:$false
Add-RoleGroupMember -Identity "discovery management" -Member goran.manot -Confirm:$false