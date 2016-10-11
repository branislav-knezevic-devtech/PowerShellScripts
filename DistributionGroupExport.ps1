#################
# SOURCE SERVER #
#################

#Create session to source
Write-Host " "
Write-Host "Connecting to Source Server"
Write-Host " "

$SourceServer = Read-Host -Prompt "Input your server name (e.g. mail.servername.com)"
$UserCredential = Get-Credential
#$SourceServer = "mail.cloudmigrationservice.net"
$SourceServerFull = "https://" + $SourceServer + "/powershell"
$SessionOptions = New-PSSessionOption –SkipCACheck –SkipCNCheck –SkipRevocationCheck
$SessionSource = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $SourceServerFull -Authentication Basic -Credential $UserCredential –SessionOption $SessionOptions
Import-PSSession $SessionSource

#Export Distribution Groups to csv
Write-Host " "
Write-Host "Exporting Distribution Groups"
Write-Host " "

Get-DistributionGroup -ResultSize unlimited | 
    Select Name, Alias, PrimarySmtpAddress, Type, MemberJoinRestriction, MemberDepartRestriction |
    Export-Csv C:\Temp\ScriptTest\DistributionGroups.csv

#Export Distribution Group Members
$DGOutputFile = "C:\Temp\ScriptTest\DistributionGroupMembers.csv"
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
Remove-PSSession -Session $SessionSource