<#
    .SYNOPSIS
        Connects to Office 365
         
    .DESCRIPTION
        Creates remote PowerShell connection to Office 365.
        This was originally a function but if it is set that way then it has problems with importing commands. 
        That can be overcomed by replacing Import-PSSession $Session with: 
        Import-Module (Import-PSSession $Session -DisableNameChecking -AllowClobber) -Global -DisableNameChecking -Force
        but in that case it returned all commands without formatting, e.g. get-mailbox goran.manot would return result
        as it has | fl at the end. It would do the same for any get command. 

    .EXAMPLE
        Connect-O365 25

        Connects to Office 365 as  goran.manot@devcmp25.onmicrosoft.com user
#>

[CmdletBinding()]
param 
(
    [Parameter(Mandatory=$true,
               Position=1,
               ValueFromPipeline=$false,
               ValueFromPipelineByPropertyName=$False)]
    [int]$DomainNumber 
)

$fullDomain = "devcmp" + $domainNumber + ".onmicrosoft.com"
$AdminName = Get-Content "D:\Credentials\Username.txt"
$FullAdminName = $AdminName + "@" + $fullDomain
$Pass = Get-Content "D:\Credentials\Password.txt" | ConvertTo-SecureString
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $FullAdminName, $Pass

if ($fullDomain -like "devcmp*.onmicrosoft.com")
{
    try
    {
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection
        Import-PSSession $Session
    }
    catch
    {
        Write-Output "Connection has failed"
        Write-Output $_.ErrorID
        Write-Output $_.Exception.Message
        break
    }
}
else
{
    $ErrorText = "Domain must be in devcmpXX
    Your entry is: $fullDomain"
    Write-Host $ErrorText -ForegroundColor Red
    break
}


 