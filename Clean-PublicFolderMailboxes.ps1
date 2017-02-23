<#
    .SYNOPSIS
        Cleanes public folder mailbox on specified destination
         
    .DESCRIPTION
        Connects to specified destination, removes all public folder mailboxes and creates a new one
    
    .EXAMPLE
        .\Clean-PublicfolderMailbox 32
    
        Removes all public folder mailboxes in @devcmp32.onmicrosoft.com destination and creates new one
#>

param 
(
    [Parameter(Mandatory=$true,
               Position=1,
               ValueFromPipeline=$false,
               ValueFromPipelineByPropertyName=$False)]
    [int]$domainNumber
)

$fullDomain = "devcmp" + $domainNumber + ".onmicrosoft.com"
if ($fullDomain -like "devcmp*.onmicrosoft.com")
{

    # connect to O365
    Write-Host "Connecting to O365" -ForegroundColor Cyan

    $AdminName = Get-Content "D:\Credentials\Username.txt"
    $FullAdminName = $AdminName + "@" + $fullDomain
    $Pass = Get-Content "D:\Credentials\Password.txt" | ConvertTo-SecureString
    $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $FullAdminName, $Pass
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection
    Import-PSSession $Session
    Connect-MsolService -Credential $Cred
    Write-Host "Session established to: $fullDomain" -ForegroundColor Green

    # Remove existing publicfolders
    Write-Host "Removing public folders" -ForegroundColor Cyan
    $mbxs = Get-Mailbox -PublicFolder
    foreach ($M in $mbxs)
    {
        Remove-Mailbox -Identity $m.name -PublicFolder -Force -Confirm:$false
        write-output "Mailbox $($m.name) has been removed"
    }

    # create public folder and add permissions to it
    Write-Host "Creating Public Folder Mailbox" -ForegroundColor Cyan

    if ( (Get-Mailbox -PublicFolder) -ne $null)
    {
        if ( (Get-Mailbox -PublicFolder).name -like "PublicFolderMailbox" )
        {
            Write-Host 'Public Folder Mailbox with name "PublicfolderMailbox" already exists' -ForegroundColor Yellow
        }
        else
        {
            New-Mailbox -Name PublicFolderMailbox -PublicFolder | Out-Null
            Add-PublicFolderClientPermission \ -User goran.manot -AccessRights owner | Out-Null
            $PFMailbox = (Get-Mailbox -publicfolder).name
            Write-Output "Public folder Mailbox: $PFMailbox has been created"
        }
    }
    else
    {
        New-Mailbox -Name "PublicFolderMailbox" -PublicFolder | Out-Null
        Add-PublicFolderClientPermission \ -User goran.manot -AccessRights owner | Out-Null
        $PFMailbox = (Get-Mailbox -publicfolder).name
        Write-Output "Public folder Mailbox: $PFMailbox has been created"
    }
    Set-OrganizationConfig -DefaultPublicFolderProhibitPostQuota 53687091200
    Set-OrganizationConfig -DefaultPublicFolderIssueWarningQuota 53687091200
}
else
{
    $ErrorText = "Domain must be in devcmpXX.onmicrosoft.com format.
    Your entry is: $fullDomain"
    Write-Host $ErrorText -ForegroundColor Red
    break
}