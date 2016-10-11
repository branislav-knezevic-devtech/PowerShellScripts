Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox | 
    Select Name, Alias, Identity | 
    Export-Csv C:\Temp\ScriptTest\SharedMailboxes.csv

Get-Mailbox -RecipientTypeDetails SharedMailbox| 
    Get-MailboxPermission | 
    where { ($_.IsInherited -eq $false) -and -not ($_.User -like “NT AUTHORITY\SELF”) } |
    Export-Csv C:\Temp\ScriptTest\MailboxPermissions.csv

$SharedMailboxes = Import-CSV -Path C:\Temp\ScriptTest\SharedMailboxes.csv |
     Select-Object @{ expression={$_.Identity}; label='IdentityEdited' }, Alias |
         Export-Csv -NoTypeInformation C:\Temp\ScriptTest\SharedMailboxesEdited.csv
$SharedMailboxesEdited = Import-CSV -Path C:\Temp\ScriptTest\SharedMailboxesEdited.csv
$SMIdentityEdited = $_.IdentityEdited
$SMAlias = $_.Alias
$SharedMailboxPermissions = Import-CSV -Path C:\Temp\ScriptTest\MailboxPermissions.csv
$SMIdentityPermission = $_.Identity
$SMUserPermission = $_.User.Split("\")
$SMUserAlias = $SMUserPermission[1]
$SMAccessRights = $_.AccessRights
$SharedMailboxPermissions | ForEach-Object { 
    if (
       $SMIdentityEdited = $SMIdentityPermission) {
       Add-MailboxPermission $SMAlias -User $SMUserAlias -AccessRights $SMAccessRights
       }

#split mora ici u okviru foreach



#####################################################

if ($SMIdentity = $SMIdentityPermission)
    {$SMIdentityPermission -replace $SMAlias}

    $staff = "X:\test.csv"

Import-Module ActiveDirectory
(Import-Csv $staff -Header "name","federated_id","username") | sort "name" -Unique | ForEach-Object {
	$samAccountName = $_."username"
	if($samAccountName -contains "@pampaisd.net")
	{
		$samAccountName -Replace "@pampaisd.net","" 
		$_."username" = $samAccountName `
		| Set-ADUser -Add @{employeeID = ($_."federated_id")}
		}
	} | Export-Csv X:\pearson_staff.csv -NoTypeInformation


Get-Mailbox -ResultSize unlimited -RecipientTypeDetails sharedmailbox | Export-Csv C:\Temp\ScriptTest\SharedMailboxes1.csv

#Export Shared Mailboxes to csv

Write-Host `n "Exporting Shared mailboxes" `n




$SharedMailboxes = Import-CSV -Path C:\Temp\ScriptTest\SharedMailboxes.csv
$SMIdentity = $_.Identity
$SMAlias = $_.Alias
$SharedMailboxPermissions = Import-CSV -Path C:\Temp\ScriptTest\MailboxPermissions.csv
$SMIdentityPermission = $_.Identity
if ($SMIdentity = $SMIdentityPermission)
    {$SMIdentityPermission -replace $SMAlias}




$SharedMailboxes | ForEach-Object {
    $SMFullName = $_.Name
    $SMSplitName = $SMFullName.Split(" ")
    $SMFirstName = $SMSplitName[0]
    $SMLastName = $SMSplitName[1]
    $SMAlias = $_.Alias
    $SMTotalImports = $SharedMailboxes.count
    $SMCounter++
    $SMProgress = [int]($SMCounter / $SMTotalImports * 100)
        Write-Progress -Activity "Importing Shared mailboxes" -Status "Completed $SMCounter of $SMTotalImports" -PercentComplete $SMProgress
        
        New-Mailbox -Shared -FirstName $SMFirstName -LastName $SMLastName -Name $SMFullName -Alias $SMAlias |
        Out-Null
    }

#Report Number of imported items
$SMTotalDestination = (Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox).count
Write-Host "Imported $($SMTotalImports) items"
Write-Host "Total number of Shared Mailboxes on Destination Server is $($SMTotalDestination)"

