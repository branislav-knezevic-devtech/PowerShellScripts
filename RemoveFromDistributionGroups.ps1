$DGs= Get-DistributionGroup | where { (Get-DistributionGroupMember $_ | foreach {$_.PrimarySmtpAddress}) -contains "cm@accendomarkets.com"}
 
foreach( $dg in $DGs){
Remove-DistributionGroupMember $dg -Member cm@accendomarkets.com
}