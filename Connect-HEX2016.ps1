<#
    .SYNOPSIS
        Connects to HEX2016
         
    .DESCRIPTION
        Creates remote PowerShell connection to Hosted Exchange Server 2016 as admin (GM)
        This was originally a function but if it is set that way then it has problems with importing commands. 
        That can be overcomed by replacing Import-PSSession $Session with: 
        Import-Module (Import-PSSession $Session -DisableNameChecking -AllowClobber) -Global -DisableNameChecking -Force
        but in that case it returned all commands without formatting, e.g. get-mailbox goran.manot would return result
        as it has | fl at the end. It would do the same for any get command.

    .EXAMPLE
        Connect-HEX2016_BK
    
        Connects to Hosted Exchange server 2016 as primary admin (GM)
#>
    
$fullDomain = "hex2016.devtech-labs.com"
$AdminName = Get-Content "D:\Credentials\Username.txt"
$FullAdminName = $AdminName + "@" + $fullDomain
$sessionName = "HEX2016"
$Pass = Get-Content "D:\Credentials\Password.txt" | ConvertTo-SecureString
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $FullAdminName, $Pass

try
{
    $SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://hex2016.devtech-labs.com/powershell -Authentication Basic -Credential $Cred –SessionOption $SessionOptions -Name $sessionName -ErrorAction stop
    Import-PSSession $Session 
    Write-Host "Connected to $sessionName" -ForegroundColor Green
}
catch
{
    $loggedError = $_
    Write-Output "Write-Output "Connection has failed""
    Write-Output "LoggedError is:" $loggedError.exception.message
    Write-Output "Number of the line which contans the error:" $loggedError.invocationInfo.scriptLineNumber
    Write-Output "Line where the error occured:" $loggedError.invocationInfo.line
    break
}


 


