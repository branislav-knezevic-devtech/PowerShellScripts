function Connect-HEX2016_BK
{
    <#
        .SYNOPSIS
            Connects to HEX2016
             
        .DESCRIPTION
            Creates remote PowerShell connection to Hosted Exchange Server 2016 as Goran Manot

        .EXAMPLE
            Connect-HEX2016_BK
    
            Connects to Hosted Exchange server 2016 as goran.manot@srchex2016.devtech-labs.com
    #>
    
    $AdminName = "goran.manot@srchex2016.devtech-labs.com"
    $Pass = Get-Content "D:\Credentials\Credentials.txt" | ConvertTo-SecureString
    $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $Pass
    
    try
    {
        $SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://hex2016.devtech-labs.com/powershell -Authentication Basic -Credential $Cred –SessionOption $SessionOptions
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

 


