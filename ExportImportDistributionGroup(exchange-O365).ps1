#################
# SOURCE SERVER #
#################

#Create session to source
Write-Host " "
Write-Host "Connecting to Source Server" -ForegroundColor Cyan
Write-Host " "

$SourceServer = Read-Host -Prompt "Input your server name (e.g. mail.servername.com)"
$UserCredential = Get-Credential
$SourceServerFull = "https://" + $SourceServer + "/powershell"
$SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
$SessionSource = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $SourceServerFull -Authentication Basic -Credential $UserCredential –SessionOption $SessionOptions
Import-PSSession $SessionSource

#Create Directory for temporary CSV files
$TestScriptMigration = Test-Path C:\Temp\ScriptMigration
if($TestScriptMigration -eq $false)
    {
    New-Item -ItemType directory -Path C:\Temp\ScriptMigration |
        Out-Null
    }

#Export Distribution Groups to csv
Write-Host " "
Write-Host "Exporting Distribution Groups" -ForegroundColor Cyan
Write-Host " "

Get-DistributionGroup -ResultSize unlimited | 
    Select Name, Alias, PrimarySmtpAddress, Type, MemberJoinRestriction, RequireSenderAuthenticationEnabled |
    Export-Csv C:\Temp\ScriptMigration\DistributionGroups.csv

#Export Distribution Group Members
$DGOutputFile = "C:\Temp\ScriptMigration\DistributionGroupMembers.csv"
Out-File -FilePath $DGOutputFile -InputObject "DGDisplayName,DGAlias,DGPRimarySmtpAddress,DGMemberName,DGMemberPrimarySmtpAddress,DGMemberAlias,DGRecipientType" -Encoding UTF8 
  
#Get all Distribution Groups from source server  
$objDistributionGroups = Get-DistributionGroup -ResultSize Unlimited  
  
#Iterate through all groups, one at a time      
Foreach ($objDistributionGroup in $objDistributionGroups)  
{      
     
    write-host "Processing $($objDistributionGroup.DisplayName)..."  
  
    #Get members of this group  
    $objDGMembers = Get-DistributionGroupMember -Identity $($objDistributionGroup.PrimarySmtpAddress)  
      
    write-host "Found $($objDGMembers.Count) members..."  
      
    #Iterate through each member  
    Foreach ($objMember in $objDGMembers)  
    {  
        Out-File -FilePath $DGOutputFile -InputObject "$($objDistributionGroup.DisplayName),$($objDistributionGroup.Alias),$($objDistributionGroup.PrimarySMTPAddress),$($objMember.DisplayName),$($objMember.PrimarySMTPAddress),$($objMember.Alias),$($objMember.RecipientType)" -Encoding UTF8 -append  
    }  
}

#End session on source
Write-Host " "
Write-Host "Disconnecting from Source Server" -ForegroundColor Cyan 
Write-Host " "

Remove-PSSession -Session $SessionSource


######################
# DESTINATION SERVER #
######################

#Create session to destination
Write-Host " "
Write-Host "Connecting to Destination Server" -ForegroundColor Cyan 
Write-Host " "
$LiveCred = Get-Credential
$SessionDestination = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $SessionDestination


#Import Distribution Groups from CSV
Write-Host " "
Write-Host "Importing Distribution Groups" -ForegroundColor Cyan
Write-Host " "

$DistributionGroups = Import-CSV -Path C:\Temp\ScriptMigration\DistributionGroups.csv
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
Write-Host "Importing Distribution Group Members" -ForegroundColor Cyan
Write-Host " "

$DistributionGroupMembers = Import-CSV -Path C:\Temp\ScriptMigration\DistributionGroupMembers.csv
$DistributionGroupMembers | ForEach-Object {
    $DGAlias1 = $_.DGAlias
    $DGMemberAlias = $_.DGMemberAlias
    Add-DistributionGroupMember -Identity $DGAlias1 -Member $DGMemberAlias
    }

#End session on destination
Write-Host " "
Write-Host "Disconnecting from Destination Server" -ForegroundColor Cyan 
Write-Host " "
Remove-PSSession -Session $SessionDestination

#Remove CSV Files
Remove-Item -Path C:\Temp\ScriptMigration -Force -Confirm:$false -Recurse


Write-Host " "
Write-Host "Migration of Distribution Groups is now complete" -ForegroundColor Cyan
Write-Host " "

Pause