function Get-BootTime_BK
{
    <#
    .SYNOPSIS
        Returns boot time of the computer

    .EXAMPLE
        Get-BootTime_BK

        Wednesday, November 16, 2016 9:28:17 AM
    #>

    ((Get-WmiObject Win32_OperatingSystem).ConvertToDateTime((Get-WmiObject Win32_OperatingSystem).LastBootUpTime))
}