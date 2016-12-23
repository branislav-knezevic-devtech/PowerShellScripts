
<#
    .SYNOPSIS
        Connects to HEX2013
         
    .DESCRIPTION
        Creates remote PowerShell connection to Hosted Exchange Server 2013. If only script is used, it connects as (GM), if some other user is needed, username needs to be specified.
		This was originally a function but if it is set that way then it has problems with importing commands. 
        That can be overcomed by replacing Import-PSSession $Session with: 
        Import-Module (Import-PSSession $Session -DisableNameChecking -AllowClobber) -Global -DisableNameChecking -Force
        but in that case it returned all commands without formatting, e.g. get-mailbox goran.manot would return result
        as it has | fl at the end. It would do the same for any get command. 

    .EXAMPLE
        .\Connect-HEX2013.ps1 amazon

        Connects to Hosted Exchange server 2013 as amazon user

    .EXAMPLE
        .\Connect-HEX2013.ps1
            
        Connects to Hosted Exchange server 2013 as default admin user (GM)
#>

[CmdletBinding()]
param 
(
    [Parameter(Mandatory=$false,
               Position=1,
               ValueFromPipeline=$false,
               ValueFromPipelineByPropertyName=$False)]
    [String]$Username 
)

if ( $username -eq "amazon") 
{
	$AdminName = Get-Content "D:\Credentials\Username-HEX2013-a.txt"
    $sessionName = "Amazon"
}
elseif ( $username -eq "google" )
{
	$AdminName = Get-Content "D:\Credentials\Username-HEX2013-g.txt"
    $sessionName = "Google"
}
elseif ( $username -eq "microsoft" )
{
	$AdminName = Get-Content "D:\Credentials\Username-HEX2013-m.txt"
    $sessionName = "Microsoft"
} 
elseif ( $Username -eq $null ) 
{
	$AdminNamePart = Get-Content "D:\Credentials\Username.txt"
	$AdminName = $AdminNamePart + "@hex2013.devtech-labs.com"
    $sessionName = "HEX2013"
}
else
{
    if ( ($Username -notlike "amazon") -or ($Username -notlike "google") -or ($Username -notlike "microsoft") -or ($Username -notlike $null) )
    {
        Write-Output "You have entered the wrong username. You must enter amazon, google, microsoft or leave it blank"
    }
}

    
$Pass = Get-Content "D:\Credentials\Password.txt" | ConvertTo-SecureString
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $Pass

try
{
    $SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://hex2013.devtech-labs.com/powershell -Authentication Basic -Credential $Cred -Name $sessionName –SessionOption $SessionOptions -ErrorAction stop

    Import-PSSession $Session
    Write-Output "Connected Session is $sessionName"
}
catch
{
    Write-Output "Connection has failed"
    # Write-Output $Error
    Write-Output $_.ErrorID
    Write-Output $_.Exception.Message
    break
}




 





