<#
    Install all Windows features needed for CMP Webserver on Windows Server 2012 R2
    Can be used as a bootstrap script
#>
$NewFeatures = @("Application-Server", "AS-NET-Framework", "AS-TCP-Port-Sharing", "AS-WAS-Support", "AS-HTTP-Activation", "AS-Named-Pipes", "AS-TCP-Activation", "Web-Server", "Web-Common-Http", "Web-Default-Doc", "Web-Dir-Browsing", "Web-Http-Errors",`
                   "Web-Static-Content", "Web-Http-Redirect", "Web-Health", "Web-Http-Logging", "Web-Log-Libraries", "Web-Request-Monitor", "Web-Performance", "Web-Stat-Compression", "Web-Dyn-Compression", "Web-Security", "Web-Filtering", `
                   "Web-Basic-Auth", "Web-App-Dev", "Web-Net-Ext", "Web-Net-Ext45", "Web-Asp-Net", "Web-Asp-Net45", "Web-ISAPI-Ext", "Web-ISAPI-Filter", "Web-WebSockets", "Web-Ftp-Server", "Web-Mgmt-Tools", "Web-Mgmt-Console", "Web-Mgmt-Compat",`
                   "Web-Metabase", "Web-Lgcy-Mgmt-Console", "Web-Lgcy-Scripting", "Web-WMI", "Web-Mgmt-Service", "NET-Framework-Features", "NET-Framework-Core", "NET-Framework-45-Features", "NET-Framework-45-Core", "NET-Framework-45-ASPNET".`
                   "NET-WCF-Services45", "NET-WCF-HTTP-Activation45", "NET-WCF-Pipe-Activation45", "NET-WCF-TCP-Activation45", "NET-WCF-TCP-PortSharing45", "FS-SMB1", "Telnet-Client", "User-Interfaces-Infra", "Server-Gui-Mgmt-Infra", "Server-Gui-Shell",`
                   "PowerShellRoot", "PowerShell", "PowerShell-V2", "PowerShell-ISE", "WAS", "WAS-Process-Model", "WAS-NET-Environment", "WAS-Config-APIs", "WoW64-Support")
$InstalledFeatures = (Get-WindowsFeature | where {$_.installState -eq "installed"}).name
$RemovedFeatures = (Get-WindowsFeature | where {$_.installState -eq "removed"}).name
ForEach ($f in $NewFeatures)
{
    if ($RemovedFeatures -contains $f )
    {
        Write-Output "Feature $f can't be installed on this version of OS as it is no longer supported" | Out-File C:\IntallationReport.txt -Append
    }
    elseif ($InstalledFeatures -notcontains $f)
    {
        Install-WindowsFeature -Name $f -Confirm:$false
        Write-Output "Feature $f installed" | Out-File C:\IntallationReport.txt -Append
    }
    else
    {
        Write-Output "Feature $f is already installed on this system" | Out-File C:\IntallationReport.txt -Append
    }
}

Restart-Computer -Force