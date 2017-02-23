function Clean-PublicFolders_BK
{
    <#
        .SYNOPSIS
            Removes Public Folders in selected destination

        .DESCRIPTION
            Connects to selected destination and removes all public folders from it

        .EXAMPLE
            Clean-PublicFolders_BK 18

            This command will remove all Public Folders on @devcmp18.onmicrosoft.com destination
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
    
        # remove all public folders
        Write-Host "Public folders are being erased" -ForegroundColor Cyan
        do
        {
            $pfs = Get-PublicFolder \ -Recurse | where { $_.identity -notlike "\" }
            foreach ($pf in $pfs)
            {
                $pfIdentity = $pf.Identity
                Remove-PublicFolder $pfIdentity -Confirm:$false -ErrorAction "SilentlyContinue"
                $pfCount = (get-publicFolder \ -Recurse).count
                if ( (Get-PublicFolder \ -Recurse | where { $_.identity -notlike "\" }) -ne $null )
                {
                    Write-Output "Remaining Public Folders: $pfCount"
                }
            }
        }
        until
        (
            (Get-PublicFolder \ -Recurse | where { $_.identity -notlike "\" }) -eq $null
        )
        Write-Output "All public folders have been removed"
    }
    else
    {
        $ErrorText = "Domain must be in devcmpXX.onmicrosoft.com format.
        Your entry is: $fullDomain"
        Write-Host $ErrorText -ForegroundColor Red
        break
    }
}