# .SYNOPSIS
# PublicFolderToMailboxMapGenerator.ps1
#    Generates a CSV file that contains the mapping of public folder branch to mailbox
#
# .DESCRIPTION
#
# Copyright (c) 2011 Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
param(
    # Mailbox size 
    [Parameter(
	Mandatory=$true,
        HelpMessage = "Size (in Bytes) of any one of the Public folder mailboxes in destination. (E.g. For 1GB enter 1 followed by nine 0's)")]
    [long] $MailboxSize,

    # File to import from
    [Parameter(
        Mandatory=$true,
        HelpMessage = "This is the path to a CSV formatted file that contains the folder names and their sizes.")]
    [ValidateNotNull()]
    [string] $ImportFile,

    # File to export to
    [Parameter(
        Mandatory=$true,
        HelpMessage = "Full path of the output file to be generated. If only filename is specified, then the output file will be generated in the current directory.")]
    [ValidateNotNull()]
    [string] $ExportFile
    )

# Folder Node's member indices
# This is an optimization since creating and storing objects as PSObject types
# is an expensive operation in powershell
# CLASSNAME_MEMBERNAME
$script:FOLDERNODE_PATH = 0;
$script:FOLDERNODE_MAILBOX = 1;
$script:FOLDERNODE_TOTALITEMSIZE = 2;
$script:FOLDERNODE_AGGREGATETOTALITEMSIZE = 3;
$script:FOLDERNODE_PARENT = 4;
$script:FOLDERNODE_CHILDREN = 5;
$script:MAILBOX_NAME = 0;
$script:MAILBOX_UNUSEDSIZE = 1;
$script:MAILBOX_ISINHERITED = 2;

$script:ROOT = @("`\", $null, 0, 0, $null, @{});

#load hashtable of localized string
Import-LocalizedData -BindingVariable MapGenerator_LocalizedStrings -FileName PublicFolderToMailboxMapGenerator.strings.psd1

# Function that constructs the entire tree based on the folderpath
# As and when it constructs it computes its aggregate folder size that included itself
function LoadFolderHierarchy() 
{
    foreach ($folder in $script:PublicFolders)
    {
        $folderSize = [long]$folder.FolderSize;
        if ($folderSize -gt $MailboxSize)
        {
            Write-Host "[$($(Get-Date).ToString())]" ($MapGenerator_LocalizedStrings.MammothFolder -f $folder, $folderSize, $MailboxSize);
            return $false;
        }

        # Start from root
        $parent = $script:ROOT;
        foreach ($familyMember in $folder.FolderName.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries))
        {            
            # Try to locate the appropriate subfolder
            $child = $parent[$script:FOLDERNODE_CHILDREN].Item($familyMember);
            if ($child -eq $null)
            {
                # Create and add subfolder to parent's children
                $child = @($folder.FolderName, $null, $folderSize, $folderSize, $parent, @{});
                $parent[$script:FOLDERNODE_CHILDREN].Add($familyMember, $child);
            }

            # Add child's individual size to parent's aggregate size
            $parent[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE] += $folderSize;
            $parent = $child;
        }
    }

    return $true;
}

# Function that assigns content mailboxes to public folders
# $node: Root node to be assigned to a mailbox
# $mailboxName: If not $null, we will attempt to accomodate folder in this mailbox
function AllocateMailbox()
{
    param ($node, $mailboxName)

    if ($mailboxName -ne $null)
    {
        # Since a mailbox was supplied by the caller, we should first attempt to use it
        if ($node[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE] -le $script:PublicFolderMailboxes[$mailboxName][$script:MAILBOX_UNUSEDSIZE])
        {
            # Node's contents (including branch) can be completely fit into specified mailbox
            # Assign the folder to mailbox and update mailbox's remaining size
            $node[$script:FOLDERNODE_MAILBOX] = $mailboxName;
            $script:PublicFolderMailboxes[$mailboxName][$script:MAILBOX_UNUSEDSIZE] -= $node[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE];
            if ($script:PublicFolderMailboxes[$mailboxName][$script:MAILBOX_ISINHERITED] -eq $false)
            {
                # This mailbox was not parent's content mailbox, but was created by a sibling
                $script:AssignedFolders += New-Object PSObject -Property @{FolderPath = $node[$script:FOLDERNODE_PATH]; TargetMailbox = $node[$script:FOLDERNODE_MAILBOX]};
            }

            return $mailboxName;
        }
    }

    $newMailboxName = "Mailbox" + ($script:NEXT_MAILBOX++);
    $script:PublicFolderMailboxes[$newMailboxName] = @($newMailboxName, $MailboxSize, $false);

    $node[$script:FOLDERNODE_MAILBOX] = $newMailboxName;
    $script:AssignedFolders += New-Object PSObject -Property @{FolderPath = $node[$script:FOLDERNODE_PATH]; TargetMailbox = $node[$script:FOLDERNODE_MAILBOX]};
    if ($node[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE] -le $script:PublicFolderMailboxes[$newMailboxName][$script:MAILBOX_UNUSEDSIZE])
    {
        # Node's contents (including branch) can be completely fit into the newly created mailbox
        # Assign the folder to mailbox and update mailbox's remaining size
        $script:PublicFolderMailboxes[$newMailboxName][$script:MAILBOX_UNUSEDSIZE] -= $node[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE];
        return $newMailboxName;
    }
    else
    {
        # Since node's contents (including branch) could not be fitted into the newly created mailbox,
        # put it's individual contents into the mailbox
        $script:PublicFolderMailboxes[$newMailboxName][$script:MAILBOX_UNUSEDSIZE] -= $node[$script:FOLDERNODE_TOTALITEMSIZE];
    }

    $subFolders = @(@($node[$script:FOLDERNODE_CHILDREN].GetEnumerator()) | Sort @{Expression={$_.Value[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE]}; Ascending=$true});
    $script:PublicFolderMailboxes[$newMailboxName][$script:MAILBOX_ISINHERITED] = $true;
    foreach ($subFolder in $subFolders)
    {
        $newMailboxName = AllocateMailbox $subFolder.Value $newMailboxName;
    }

    return $null;
}

# Function to check if further optimization can be done on the output generated
function TryAccomodateSubFoldersWithParent()
{
    $numAssignedFolders = $script:AssignedFolders.Count;
    for ($index = $numAssignedFolders - 1 ; $index -ge 0 ; $index--)
    {
        $assignedFolder = $script:AssignedFolders[$index];

        # Locate folder's parent
        for ($jindex = $index - 1 ; $jindex -ge 0 ; $jindex--)
        {
            if ($assignedFolder.FolderPath.StartsWith($script:AssignedFolders[$jindex].FolderPath))
            {
                # Found first ancestor
                $ancestor = $script:AssignedFolders[$jindex];
                $usedMailboxSize = $MailboxSize - $script:PublicFolderMailboxes[$assignedFolder.TargetMailbox][$script:MAILBOX_UNUSEDSIZE];
                if ($usedMailboxSize -le $script:PublicFolderMailboxes[$ancestor.TargetMailbox][$script:MAILBOX_UNUSEDSIZE])
                {
					# If the current mailbox can fit into its ancestor mailbox, add the former's contents to ancestor
					# and remove the mailbox assigned to it.Update the ancestor mailbox's size accordingly
                    $script:PublicFolderMailboxes[$assignedFolder.TargetMailbox][$script:MAILBOX_UNUSEDSIZE] = $MailboxSize;
                    $script:PublicFolderMailboxes[$ancestor.TargetMailbox][$script:MAILBOX_UNUSEDSIZE] -= $usedMailboxSize;
                    $assignedFolder.TargetMailbox = $null;
                }

                break;
            }
        }
    }
    
    if ($script:AssignedFolders.Count -gt 1)
    {
        $script:AssignedFolders = $script:AssignedFolders | where {$_.TargetMailbox -ne $null};
    }
}

# Parse the CSV file
Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.ProcessFolder;
$script:PublicFolders = Import-CSV $ImportFile;

# Check if there is atleast one public folder in existence
if (!$script:PublicFolders)
{
    Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.ProcessEmptyFile;
    return;
}

Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.LoadFolderHierarchy;
$loadHierarchy = LoadFolderHierarchy;
if ($loadHierarchy -ne $true)
{
    Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.CannotLoadFolders;
    return;
}

# Contains the list of instantiated public folder maiboxes
# Key: mailbox name, Value: unused mailbox size
$script:PublicFolderMailboxes = @{};
$script:AssignedFolders = @();
$script:NEXT_MAILBOX = 1;

Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.AllocateFolders;
$ignoreReturnValue = AllocateMailbox $script:ROOT $null;

Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.AccomodateFolders;
TryAccomodateSubFoldersWithParent;

Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.ExportFolderMap;
$script:NEXT_MAILBOX = 2;
$previous = $script:AssignedFolders[0];
$previousOriginalMailboxName = $script:AssignedFolders[0].TargetMailbox;
$numAssignedFolders = $script:AssignedFolders.Count;

# Prepare the folder object that is to be finally exported
# During the process, rename the mailbox assigned to it.  
# This is done to prevent any gap in generated mailbox name sequence at the end of the execution of TryAccomodateSubFoldersWithParent function
for ($index = 0 ; $index -lt $numAssignedFolders ; $index++)
{
    $current = $script:AssignedFolders[$index];
    $currentMailboxName = $current.TargetMailbox;
    if ($previousOriginalMailboxName -ne $currentMailboxName)
    {
        $current.TargetMailbox = "Mailbox" + ($script:NEXT_MAILBOX++);
    }
    else
    {
        $current.TargetMailbox = $previous.TargetMailbox;
    }

    $previous = $current;
    $previousOriginalMailboxName = $currentMailboxName;
}

# Export the folder mapping to CSV file
$script:AssignedFolders | Export-CSV -Path $ExportFile -Force -NoTypeInformation -Encoding "Unicode";

# SIG # Begin signature block
# MIIa5AYJKoZIhvcNAQcCoIIa1TCCGtECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0w+0nbMI2yy4o1qD8p9+TQu7
# pwygghWCMIIEwzCCA6ugAwIBAgITMwAAAHD0GL8jIfxQnQAAAAAAcDANBgkqhkiG
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
# 9wFlb4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TGCBMwwggTI
# AgEBMIGQMHkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAh
# BgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBAhMzAAAAymzVMhI1xOFV
# AAEAAADKMAkGBSsOAwIaBQCggeUwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFL2Z
# Icpj2id/Zmychk7lWo4odUJnMIGEBgorBgEEAYI3AgEMMXYwdKBMgEoAUAB1AGIA
# bABpAGMARgBvAGwAZABlAHIAVABvAE0AYQBpAGwAYgBvAHgATQBhAHAARwBlAG4A
# ZQByAGEAdABvAHIALgBwAHMAMaEkgCJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
# ZXhjaGFuZ2UgMA0GCSqGSIb3DQEBAQUABIIBAHmuNRG/P9Sujsa5ZlvQUxFAOf75
# 9u77yRV4rpJ/+Kt+TXbuKT9BhCLznqKUZ/2czbJLzXSrrAI9cZkfy1FRA6dO2CUg
# IJJUbGbIrIWBFMSGHSiMI2C3aJGQX/+jfNhJTBR3aoNMYqumtjTbd2pIxpCfhA0Z
# 2wPkIQz6FOjaDxguy59oz9f+rABlEF48tSPg0DFPdvRacB19ZpKKnAe/3QIN7gqW
# 3e46DA+hK5fA4bBCh8n542znUgx6qj+szXrbmzi36lLhYA/76dCZdPVuKvqIe6vj
# DEHSJdfja7Bf8saW1//zL6zG+BFGaJMOO/UpJEwvljpgmbcWy7UEZpeibNqhggIo
# MIICJAYJKoZIhvcNAQkGMYICFTCCAhECAQEwgY4wdzELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBAhMzAAAAcPQYvyMh/FCdAAAAAABwMAkGBSsOAwIaBQCgXTAYBgkqhkiG
# 9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xNTA1MTkxNTQ5MzJa
# MCMGCSqGSIb3DQEJBDEWBBRyy94h+UBsCFBRa2QJEqtcpHocwjANBgkqhkiG9w0B
# AQUFAASCAQBrOu1RXdCD3YenmqW/Iypa8P7geGDx1gP6sHsOjBR9ItQGztPaDaTM
# M/IMJcJ+eMLVzqZF7dqGcZln4YoZTpKUaxBy9Oc1N5TP/hqDvERF91dEHHypc9C/
# C+pnZmf3PhAggmyxxllJUadZzekUSibW8bUaK/XlEWfdA5xzwAvwg58p8r/nwjyL
# J8Se8GVItBZapkGstZ56/wSfHo/VFuU9PCmewzO5zkPzz0hbJmsxxORscAl+zo3d
# fCubEsJUyFqRXKXooJL3W+jEPrram8xYoE+liKXl5M6P0pQZ5RBATWFiLGnxgAZL
# wrCMAySIWhrw63dgDfaU07cswqm21f9x
# SIG # End signature block
