#Create sessin
$LiveCred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $Session

#Create Distribution Group
New-DistributionGroup -Alias cmp.admins -DisplayName "CMP Administrators" -Name "CMP Administrators" -Members goran.manot@devtechgroup.com,branislav.knezevic@devtechgroup.com -MemberDepartRestriction Closed -RequireSenderAuthenticationEnabled $false