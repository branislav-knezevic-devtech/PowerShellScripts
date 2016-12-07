######################
# DESTINATION SERVER #
######################

#Create session to destination
#Write-Host " "
#Write-Host "Connecting to Destination Server"
#Write-Host " "
#$LiveCred = Get-Credential
#$SessionDestination = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
#Import-PSSession $SessionDestination


#Import Distribution Groups from CSV
Write-Host " "
Write-Host "Importing Distribution Groups"
Write-Host " "

$DistributionGroups = Import-CSV -Path C:\Temp\ScriptTest\DistributionGroups.csv
$DistributionGroups | ForEach-Object {
    $DGName = $_.Name
    $DGAlias = $_.Alias
    $DGType = if ($_.GroupType -eq "Universal") {
        "Distribution"
        } Else {
        "Security"
        }
    $DGMemberJoinRestriction = $_.MemberJoinRestriction
    $DGRequireSenderAuthenticationEnabled = if ($_.RequireSenderAuthenticationEnabled -eq "TRUE") {
        $True
        } Else {
        $False
        }
    write-host "Creating $($DGName) Distribution group..."
    New-DistributionGroup -Name $DGName -Alias $DGAlias -Type $DGType -MemberJoinRestriction $DGMemberJoinRestriction |
        Set-DistributionGroup -Alias $DGAlias -RequireSenderAuthenticationEnabled $DGRequireSenderAuthenticationEnabled |
        Out-Null
    }


#Add Distribution Group Members
Write-Host " "
Write-Host "Importing Distribution Group Members"
Write-Host " "

$DistributionGroupMembers = Import-CSV -Path C:\Temp\ScriptTest\DistributionGroupMembers.csv
$DistributionGroupMembers | ForEach-Object {
    $DGAlias1 = $_.DGAlias
    $DGMemberAlias = $_.DGMemberAlias
    Add-DistributionGroupMember -Identity $DGAlias1 -Member $DGMemberAlias
    }

#End session on destination
#Remove-PSSession -Session $SessionDestination