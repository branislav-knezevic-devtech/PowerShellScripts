function Connect-O365_BK
{
    <#
        .SYNOPSIS
            Connects to Office 365
             
        .DESCRIPTION
            Creates remote PowerShell connection to Office 365

        .EXAMPLE
            Connect-O365_bk devcmp25
    
            Connects to Office 365 as  goran.manot@devcmp25.onmicrosoft.com user
    #>

    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$true,
                   Position=1,
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$False)]
        [String]$domain 
    )

    $fullDomain = $domain + ".onmicrosoft.com"
    $AdminName = "goran.manot" + "@" + $fullDomain 
    $Pass = Get-Content "D:\Credentials\Credentials.txt" | ConvertTo-SecureString
    $Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AdminName, $Pass
    
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
}

 