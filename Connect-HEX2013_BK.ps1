function Connect-HEX2013_BK
{
    <#
        .SYNOPSIS
            Connects to HEX2013
             
        .DESCRIPTION
            Creates remote PowerShell connection to Hosted Exchange Server 2013 as Goran Manot

        .EXAMPLE
            Connect-HEX2013_BK amazon.admin
    
            Connects to Hosted Exchange server 2013 as amazon.admin@amazon.devtech-labs.com
        .EXAMPLE
            Connect-HEX2013_BK goran.manot
                
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

    if ( ($username -eq "amazon.admin") -or ($username -eq "google.admin") -or ($username -eq "microsoft.admin") -or ($username -eq "goran.manot") )
    {
        switch ($Username)
        {
            "amazon.admin" { $AdminName = "amazon.admin@amazon.devtech-labs.com" }
            "google.admin" { $AdminName = "google.admin@google.devtech-labs.com" }
            "microsoft.admin" { $AdminName = "microsoft.admin@microsoft.devtech-labs.com" }
            default { $AdminName = "goran.manot@hex2016.devtech-labs.com" }
        }
        
        $Pass = Get-Content "D:\Credentials\Credentials.txt" | ConvertTo-SecureString
        $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $Pass
        
        try
        {
            $SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
            $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://hex2013.devtech-labs.com/powershell -Authentication Basic -Credential $UserCredential –SessionOption $SessionOptions
            Import-Module (Import-PSSession $Session -DisableNameChecking -AllowClobber) -Global -DisableNameChecking -Force
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
        Write-Host "Your have entered the wrong username" -ForegroundColor Red
    }
}

 





