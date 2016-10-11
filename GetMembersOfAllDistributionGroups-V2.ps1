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