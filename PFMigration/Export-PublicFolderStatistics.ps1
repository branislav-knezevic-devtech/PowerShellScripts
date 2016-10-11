# .SYNOPSIS
# Export-PublicFolderStatistics.ps1
#    Generates a CSV file that contains the list of public folders and their individual sizes
#
# .DESCRIPTION
#
# Copyright (c) 2011 Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

Param(
    # File to export to
    [Parameter(
        Mandatory=$true,
        HelpMessage = "Full path of the output file to be generated. If only filename is specified, then the output file will be generated in the current directory.")]
    [ValidateNotNull()]
    [string] $ExportFile,
    
    # Server to connect to for generating statistics
    [Parameter(
        Mandatory=$true,
        HelpMessage = "Public folder server to enumerate the folder hierarchy.")]
    [ValidateNotNull()]
    [string] $PublicFolderServer
    )

#load hashtable of localized string
Import-LocalizedData -BindingVariable PublicFolderStatistics_LocalizedStrings -FileName Export-PublicFolderStatistics.strings.psd1
    
################ START OF DEFAULTS ################

$WarningPreference = 'SilentlyContinue';
$script:Exchange14MajorVersion = 14;
$script:Exchange12MajorVersion = 8;

################ END OF DEFAULTS #################

# Function that determines if to skip the given folder
function IsSkippableFolder()
{
    param($publicFolder);
    
    $publicFolderIdentity = $publicFolder.Identity.ToString();

    for ($index = 0; $index -lt $script:SkippedSubtree.length; $index++)
    {
        if ($publicFolderIdentity.StartsWith($script:SkippedSubtree[$index]))
        {
            return $true;
        }
    }
    
    return $false;
}

# Function that gathers information about different public folders
function GetPublicFolderDatabases()
{
    $script:ServerInfo = Get-ExchangeServer -Identity:$PublicFolderServer;
    $script:PublicFolderDatabasesInOrg = @();
    if ($script:ServerInfo.AdminDisplayVersion.Major -eq $script:Exchange14MajorVersion)
    {
        $script:PublicFolderDatabasesInOrg = @(Get-PublicFolderDatabase -IncludePreExchange2010);
    }
    elseif ($script:ServerInfo.AdminDisplayVersion.Major -eq $script:Exchange12MajorVersion)
    {
        $script:PublicFolderDatabasesInOrg = @(Get-PublicFolderDatabase -IncludePreExchange2007);
    }
    else
    {
        $script:PublicFolderDatabasesInOrg = @(Get-PublicFolderDatabase);
    }
}

# Function that executes statistics cmdlet on different public folder databases
function GatherStatistics()
{   
    # Running Get-PublicFolderStatistics against each server identified via Get-PublicFolderDatabase cmdlet
    $databaseCount = $($script:PublicFolderDatabasesInOrg.Count);
    $index = 0;
    
    if ($script:ServerInfo.AdminDisplayVersion.Major -eq $script:Exchange12MajorVersion)
    {
        $getPublicFolderStatistics = "@(Get-PublicFolderStatistics ";
    }
    else
    {
        $getPublicFolderStatistics = "@(Get-PublicFolderStatistics -ResultSize:Unlimited ";
    }

    While ($index -lt $databaseCount)
    {
        $serverName = $($script:PublicFolderDatabasesInOrg[$index]).Server.Name;
        $getPublicFolderStatisticsCommand = $getPublicFolderStatistics + "-Server $serverName)";
        Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.RetrievingStatistics -f $serverName);
        $publicFolderStatistics = Invoke-Expression $getPublicFolderStatisticsCommand;
        Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.RetrievingStatisticsComplete -f $serverName,$($publicFolderStatistics.Count));
        RemoveDuplicatesFromFolderStatistics $publicFolderStatistics;
        Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.UniqueFoldersFound -f $($script:FolderStatistics.Count));
        $index++;
    }
}

# Function that removed redundant entries from output of Get-PublicFolderStatistics
function RemoveDuplicatesFromFolderStatistics()
{
    param($publicFolders);
    
    $index = 0;
    While ($index -lt $publicFolders.Count)
    {
        $publicFolderEntryId = $($publicFolders[$index].EntryId);
        $folderSizeFromStats = $($publicFolders[$index].TotalItemSize.Value.ToBytes());
        $folderPath = $($publicFolders[$index].FolderPath);
        $existingFolder = $script:FolderStatistics[$publicFolderEntryId];
        if (($existingFolder -eq $null) -or ($folderSizeFromStats -gt $existingFolder[0]))
        {
            $newFolder = @();
            $newFolder += $folderSizeFromStats;
            $newFolder += $folderPath;
            $script:FolderStatistics[$publicFolderEntryId] = $newFolder;
        }
       
        $index++;
    }    
}

# Function that creates folder objects in right way for exporting
function CreateFolderObjects()
{   
    $index = 1;
    foreach ($publicFolderEntryId in $script:FolderStatistics.Keys)
    {
        $existingFolder = $script:NonIpmSubtreeFolders[$publicFolderEntryId];
        $publicFolderIdentity = "";
        if ($existingFolder -ne $null)
        {
            $result = IsSkippableFolder($existingFolder);
            if (!$result)
            {
                $publicFolderIdentity = "\NON_IPM_SUBTREE\" + $script:FolderStatistics[$publicFolderEntryId][1];
                $folderSize = $script:FolderStatistics[$publicFolderEntryId][0];
            }
        }  
        else
        {
            $publicFolderIdentity = "\IPM_SUBTREE\" + $script:FolderStatistics[$publicFolderEntryId][1];
            $folderSize = $script:FolderStatistics[$publicFolderEntryId][0];
        }  
        
        if ($publicFolderIdentity -ne "")
        {
            if(($index%10000) -eq 0)
            {
                Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.ProcessedFolders -f $index);
            }
            
            # Create a folder object to be exported to a CSV
            $newFolderObject = New-Object PSObject -Property @{FolderName = $publicFolderIdentity; FolderSize = $folderSize}
            $retValue = $script:ExportFolders.Add($newFolderObject);
            $index++;
        }
    }   
}

####################################################################################################
# Script starts here
####################################################################################################

# Array of folder objects for exporting
$script:ExportFolders = $null;

# Hash table that contains the folder list
$script:FolderStatistics = @{};

# Hash table that contains the folder list
$script:NonIpmSubtreeFolders = @{};

# Folders that are skipped while computing statistics
$script:SkippedSubtree = @("\NON_IPM_SUBTREE\OFFLINE ADDRESS BOOK", "\NON_IPM_SUBTREE\SCHEDULE+ FREE BUSY",
                           "\NON_IPM_SUBTREE\schema-root", "\NON_IPM_SUBTREE\OWAScratchPad",
                           "\NON_IPM_SUBTREE\StoreEvents", "\NON_IPM_SUBTREE\Events Root");

Write-Host "[$($(Get-Date).ToString())]" $PublicFolderStatistics_LocalizedStrings.ProcessingNonIpmSubtree;
$nonIpmSubtreeFolderList = Get-PublicFolder "\NON_IPM_SUBTREE" -Server $PublicFolderServer -Recurse -ResultSize:Unlimited;
Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.ProcessingNonIpmSubtreeComplete -f $($nonIpmSubtreeFolderList.Count));
foreach ($nonIpmSubtreeFolder in $nonIpmSubtreeFolderList)
{
    $script:NonIpmSubtreeFolders.Add($nonIpmSubtreeFolder.EntryId, $nonIpmSubtreeFolder); 
}

# Determining the public folder database deployment in the organization
GetPublicFolderDatabases;

# Gathering statistics from each server
GatherStatistics;

# Allocating space here
$script:ExportFolders = New-Object System.Collections.ArrayList -ArgumentList ($script:FolderStatistics.Count + 3);

# Creating folder objects for exporting to a CSV
Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.ExportStatistics -f $($script:FolderStatistics.Count));
CreateFolderObjects;

# Creating folder objects for all the skipped root folders
$newFolderObject = New-Object PSObject -Property @{FolderName = "\IPM_SUBTREE"; FolderSize = 0};
# Ignore the return value
$retValue = $script:ExportFolders.Add($newFolderObject);
$newFolderObject = New-Object PSObject -Property @{FolderName = "\NON_IPM_SUBTREE"; FolderSize = 0};
$retValue = $script:ExportFolders.Add($newFolderObject);
$newFolderObject = New-Object PSObject -Property @{FolderName = "\NON_IPM_SUBTREE\EFORMS REGISTRY"; FolderSize = 0};
$retValue = $script:ExportFolders.Add($newFolderObject);

# Export the folders to CSV file
Write-Host "[$($(Get-Date).ToString())]" $PublicFolderStatistics_LocalizedStrings.ExportToCSV;
$script:ExportFolders | Sort-Object -Property FolderName | Export-CSV -Path $ExportFile -Force -NoTypeInformation -Encoding "Unicode";

# SIG # Begin signature block
# MIIa2wYJKoZIhvcNAQcCoIIazDCCGsgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULPvD1y8oczpC9FeHiXZx+SMr
# 7xigghWCMIIEwzCCA6ugAwIBAgITMwAAAHD0GL8jIfxQnQAAAAAAcDANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTUwMzIwMTczMjAy
# WhcNMTYwNjIwMTczMjAyWjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# OkY1MjgtMzc3Ny04QTc2MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoxTZ7xygeRG9
# LZoEnSM0gqVCHSsA0dIbMSnIKivzLfRui93iG/gT9MBfcFOv5zMPdEoHFGzcKAO4
# Kgp4xG4gjguAb1Z7k/RxT8LTq8bsLa6V0GNnsGSmNAMM44quKFICmTX5PGTbKzJ3
# wjTuUh5flwZ0CX/wovfVkercYttThkdujAFb4iV7ePw9coMie1mToq+TyRgu5/YK
# VA6YDWUGV3eTka+Ur4S+uG+thPT7FeKT4thINnVZMgENcXYAlUlpbNTGNjpaMNDA
# ynOJ5pT2Ix4SYFEACMHe2j9IhO21r9TTmjiVqbqjWLV4aEa/D4xjcb46Q0NZEPBK
# unvW5QYT3QIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFG3P87iErvfMdr24e6w9l2GB
# dCsnMB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBAF46KvVn9AUwKt7hue9n/Cr/bnIpn558xxPDo+WOPATpJhVN
# 98JnglwKW8UK7lXwoy2Ooh2isywt0BHimioB0TAmZ6GmbokxHG7dxHFU8Ami3cHW
# NnPADP9VCGv8oZT9XSwnIezRIwbcBCzvuQLbA7tHcxgK632ZzV8G4Ij3ipPFEhEb
# 81KVo3Kg0ljZwyzia3931GNT6oK4L0dkKJjHgzvxayhh+AqIgkVSkumDJklct848
# mn+voFGTxby6y9ErtbuQGQqmp2p++P0VfkZEh6UG1PxKcDjG6LVK9NuuL+xDyYmi
# KMVV2cG6W6pgu6W7+dUCjg4PbcI1cMCo7A2hsrgwggTsMIID1KADAgECAhMzAAAA
# ymzVMhI1xOFVAAEAAADKMA0GCSqGSIb3DQEBBQUAMHkxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBMB4XDTE0MDQyMjE3MzkwMFoXDTE1MDcyMjE3MzkwMFowgYMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIx
# HjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAJZxXe0GRvqEy51bt0bHsOG0ETkDrbEVc2Cc66e2bho8
# P/9l4zTxpqUhXlaZbFjkkqEKXMLT3FIvDGWaIGFAUzGcbI8hfbr5/hNQUmCVOlu5
# WKV0YUGplOCtJk5MoZdwSSdefGfKTx5xhEa8HUu24g/FxifJB+Z6CqUXABlMcEU4
# LYG0UKrFZ9H6ebzFzKFym/QlNJj4VN8SOTgSL6RrpZp+x2LR3M/tPTT4ud81MLrs
# eTKp4amsVU1Mf0xWwxMLdvEH+cxHrPuI1VKlHij6PS3Pz4SYhnFlEc+FyQlEhuFv
# 57H8rEBEpamLIz+CSZ3VlllQE1kYc/9DDK0r1H8wQGcCAwEAAaOCAWAwggFcMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBQfXuJdUI1Whr5KPM8E6KeHtcu/
# gzBRBgNVHREESjBIpEYwRDENMAsGA1UECxMETU9QUjEzMDEGA1UEBRMqMzE1OTUr
# YjQyMThmMTMtNmZjYS00OTBmLTljNDctM2ZjNTU3ZGZjNDQwMB8GA1UdIwQYMBaA
# FMsR6MrStBZYAck3LjMWFrlMmgofMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY0NvZFNpZ1BDQV8w
# OC0zMS0yMDEwLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljQ29kU2lnUENBXzA4LTMx
# LTIwMTAuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQB3XOvXkT3NvXuD2YWpsEOdc3wX
# yQ/tNtvHtSwbXvtUBTqDcUCBCaK3cSZe1n22bDvJql9dAxgqHSd+B+nFZR+1zw23
# VMcoOFqI53vBGbZWMrrizMuT269uD11E9dSw7xvVTsGvDu8gm/Lh/idd6MX/YfYZ
# 0igKIp3fzXCCnhhy2CPMeixD7v/qwODmHaqelzMAUm8HuNOIbN6kBjWnwlOGZRF3
# CY81WbnYhqgA/vgxfSz0jAWdwMHVd3Js6U1ZJoPxwrKIV5M1AHxQK7xZ/P4cKTiC
# 095Sl0UpGE6WW526Xxuj8SdQ6geV6G00DThX3DcoNZU6OJzU7WqFXQ4iEV57MIIF
# vDCCA6SgAwIBAgIKYTMmGgAAAAAAMTANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZIm
# iZPyLGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQD
# EyRNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTAwODMx
# MjIxOTMyWhcNMjAwODMxMjIyOTMyWjB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSMwIQYDVQQDExpNaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBD
# QTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJyWVwZMGS/HZpgICBC
# mXZTbD4b1m/My/Hqa/6XFhDg3zp0gxq3L6Ay7P/ewkJOI9VyANs1VwqJyq4gSfTw
# aKxNS42lvXlLcZtHB9r9Jd+ddYjPqnNEf9eB2/O98jakyVxF3K+tPeAoaJcap6Vy
# c1bxF5Tk/TWUcqDWdl8ed0WDhTgW0HNbBbpnUo2lsmkv2hkL/pJ0KeJ2L1TdFDBZ
# +NKNYv3LyV9GMVC5JxPkQDDPcikQKCLHN049oDI9kM2hOAaFXE5WgigqBTK3S9dP
# Y+fSLWLxRT3nrAgA9kahntFbjCZT6HqqSvJGzzc8OJ60d1ylF56NyxGPVjzBrAlf
# A9MCAwEAAaOCAV4wggFaMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFMsR6MrS
# tBZYAck3LjMWFrlMmgofMAsGA1UdDwQEAwIBhjASBgkrBgEEAYI3FQEEBQIDAQAB
# MCMGCSsGAQQBgjcVAgQWBBT90TFO0yaKleGYYDuoMW+mPLzYLTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTAfBgNVHSMEGDAWgBQOrIJgQFYnl+UlE/wq4QpTlVnk
# pDBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtp
# L2NybC9wcm9kdWN0cy9taWNyb3NvZnRyb290Y2VydC5jcmwwVAYIKwYBBQUHAQEE
# SDBGMEQGCCsGAQUFBzAChjhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2Nl
# cnRzL01pY3Jvc29mdFJvb3RDZXJ0LmNydDANBgkqhkiG9w0BAQUFAAOCAgEAWTk+
# fyZGr+tvQLEytWrrDi9uqEn361917Uw7LddDrQv+y+ktMaMjzHxQmIAhXaw9L0y6
# oqhWnONwu7i0+Hm1SXL3PupBf8rhDBdpy6WcIC36C1DEVs0t40rSvHDnqA2iA6VW
# 4LiKS1fylUKc8fPv7uOGHzQ8uFaa8FMjhSqkghyT4pQHHfLiTviMocroE6WRTsgb
# 0o9ylSpxbZsa+BzwU9ZnzCL/XB3Nooy9J7J5Y1ZEolHN+emjWFbdmwJFRC9f9Nqu
# 1IIybvyklRPk62nnqaIsvsgrEA5ljpnb9aL6EiYJZTiU8XofSrvR4Vbo0HiWGFzJ
# NRZf3ZMdSY4tvq00RBzuEBUaAF3dNVshzpjHCe6FDoxPbQ4TTj18KUicctHzbMrB
# 7HCjV5JXfZSNoBtIA1r3z6NnCnSlNu0tLxfI5nI3EvRvsTxngvlSso0zFmUeDord
# EN5k9G/ORtTTF+l5xAS00/ss3x+KnqwK+xMnQK3k+eGpf0a7B2BHZWBATrBC7E7t
# s3Z52Ao0CW0cgDEf4g5U3eWh++VHEK1kmP9QFi58vwUheuKVQSdpw5OPlcmN2Jsh
# rg1cnPCiroZogwxqLbt2awAdlq3yFnv2FoMkuYjPaqhHMS+a3ONxPdcAfmJH0c6I
# ybgY+g5yjcGjPa8CQGr/aZuW4hCoELQ3UAjWwz0wggYHMIID76ADAgECAgphFmg0
# AAAAAAAcMA0GCSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAX
# BgoJkiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMx
# MzAzMDlaMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAf
# BgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn
# 0UytdDAgEesH1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0
# Zxws/HvniB3q506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4n
# rIZPVVIM5AMs+2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YR
# JylmqJfk0waBSqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54
# QTF3zJvfO4OToWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsG
# A1UdDwQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJg
# QFYnl+UlE/wq4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcG
# CgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3Qg
# Q2VydGlmaWNhdGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJ
# MEcwRaBDoEGGP2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1
# Y3RzL21pY3Jvc29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYB
# BQUHMAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0Um9vdENlcnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEB
# BQUAA4ICAQAQl4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1i
# uFcCy04gE1CZ3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+r
# kuTnjWrVgMHmlPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGct
# xVEO6mJcPxaYiyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/F
# NSteo7/rvH0LQnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbo
# nXCUbKw5TNT2eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0
# NbhOxXEjEiZ2CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPp
# K+m79EjMLNTYMoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2J
# oXZhtG6hE6a/qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0
# eFQF1EEuUKyUsKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng
# 9wFlb4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TGCBMMwggS/
# AgEBMIGQMHkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAh
# BgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBAhMzAAAAymzVMhI1xOFV
# AAEAAADKMAkGBSsOAwIaBQCggdwwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFF23
# 7V7norP9bLEYHLRAG5Qi6mfGMHwGCisGAQQBgjcCAQwxbjBsoESAQgBFAHgAcABv
# AHIAdAAtAFAAdQBiAGwAaQBjAEYAbwBsAGQAZQByAFMAdABhAHQAaQBzAHQAaQBj
# AHMALgBwAHMAMaEkgCJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vZXhjaGFuZ2Ug
# MA0GCSqGSIb3DQEBAQUABIIBAECq2dnbxRHNGzqVglrDe4lWqnmeG5nTgUVzLMO2
# VrKsXVGLCOeVLViFwAie0Y0wfEPuKNUzVLwiu1dhlk8Ohz8ES4+SC6i/1xeqEk+K
# udgUHiY8cRxpPygvRtz6Wyh/F66OKMI6UFs0xepV+uC45lgN3W1BP/arqXrZRgWP
# JuITmxKC7O5Dq4PmUTI+xIZUpywhKd5/s+PXIvkIwIAAkqgIAh+TaV6gKm+lwglb
# lfm0wskJyzuedrMIs77QIISuoS8/FHmk+VMJY7C05pvjWnVdp0RRQ49RFLYI5Iui
# KcYYISY2aC1E6bX+ybteC0cF09av70vCZuCOIFdY2L0DgBKhggIoMIICJAYJKoZI
# hvcNAQkGMYICFTCCAhECAQEwgY4wdzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBAhMz
# AAAAcPQYvyMh/FCdAAAAAABwMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJ
# KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xNTA1MTkxNTQ5MjdaMCMGCSqGSIb3
# DQEJBDEWBBR1E3Bz2vRX+g7DBVnCk3GcoVPX/DANBgkqhkiG9w0BAQUFAASCAQBi
# eZPC/+aVszpZzOhot4Czjy7iTM1VYrLSUCeL8YqDAeNLH7XGPN8c8oY/83bTzI1Q
# BorJu6OpqZq9+pk4S6XC0S8fQRvF5fMqGGM6IBP7HlvKgDdZstNxiI/7SPOb0KwW
# dgIAoZevrFiXDQZAdE9j7baEIZlLNyYCS/Uq/7DAyZCbfNzNkK9Al3pErTHHKbYX
# TvZhBLdQyM6aCmqZzbjP3aEQViIWXoSzwDX84/hDr9GfoJNVAR4aZreFVRb9vpw3
# 7z1y+c7wmCBzca8EGuz4+xzGNcm1ZvWAmsKQZzGe6AD79r7mQtp+E+aMCQP8rMST
# fyVTst/ZK+Ty5qZDenbh
# SIG # End signature block
