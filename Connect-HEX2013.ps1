
<#
    .SYNOPSIS
        Connects to HEX2013
         
    .DESCRIPTION
        Creates remote PowerShell connection to Hosted Exchange Server 2013 as Goran Manot
		This was originally a function but if it is set that way then it has problems with importing commands. 
        That can be overcomed by replacing Import-PSSession $Session with: 
        Import-Module (Import-PSSession $Session -DisableNameChecking -AllowClobber) -Global -DisableNameChecking -Force
        but in that case it returned all commands without formatting, e.g. get-mailbox goran.manot would return result
        as it has | fl at the end. It would do the same for any get command. 

    .EXAMPLE
        .\Connect-HEX2013.psq amazon.admin

        Connects to Hosted Exchange server 2013 as amazon.admin@amazon.devtech-labs.com

    .EXAMPLE
        .\Connect-HEX2013.ps1 goran.manot
            
        Connects to Hosted Exchange server 2013 as goran.manot@hex2013.devtech-labs.com
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

if ( ($username -eq "amazon.admin") -or ($username -eq "google.admin") -or ($username -eq "microsoft.admin")  )
{
    switch ( $Username )
    {
        "amazon.admin" { $AdminName = "amazon.admin@amazon.devtech-labs.com" }
        "google.admin" { $AdminName = "google.admin@google.devtech-labs.com" }
        "microsoft.admin" { $AdminName = "microsoft.admin@microsoft.devtech-labs.com" }
		
        # default { $AdminName = "goran.manot@hex2013.devtech-labs.com" }
    }
    
    $Pass = Get-Content "D:\Credentials\Credentials.txt" | ConvertTo-SecureString
    $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $Pass
    
    try
    {
        $SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://hex2013.devtech-labs.com/powershell -Authentication Basic -Credential $Cred –SessionOption $SessionOptions
        Import-PSSession $Session
    }
    catch
    {
        Write-Output "Connection has failed"
        Write-Output $Error
		#Write-Output $_.ErrorID
        #Write-Output $_.Exception.Message
        break
    }
}
elseif ($username -eq $null)
{
	$AdminName = "goran.manot@hex2013.devtech-labs.com"
}
else
{
    Write-Host "Your have entered the wrong username" -ForegroundColor Red
}

 





