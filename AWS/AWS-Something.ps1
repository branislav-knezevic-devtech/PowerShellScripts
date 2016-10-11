Get-Module -ListAvailabe
$env:PSModulePath = $env:PSModulePath + ";C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell"
Import-Module AWSPowerShell
Initialize-AWSDefaults 
$groupid = (Get-EC2SecurityGroup -GroupName "Powershell Gruop").GroupId
$ip1 = new-object Amazon.EC2.Model.IpPermission
$ip1.IpProtocol = "tcp"
$ip1.FromPort = 23
$ip1.ToPort = 23
$ip1.IpRanges.Add("109.92.130.78/32")
$ip2 = new-object Amazon.EC2.Model.IpPermission
$ip2.IpProtocol = "tcp"
$ip2.FromPort = 443
$ip2.ToPort = 443
$ip2.IpRanges.Add("109.92.130.78/32")
Grant-EC2SecurityGroupIngress -GroupId $groupid -IpPermissions @( $ip1, $ip2 )
(Get-EC2SecurityGroup -GroupName "Powershell Gruop").IpPermissions
Get-EC2Instance -in

function Get-EC2InstanceName ($instanceId) 
{
 
$tags = (Get-EC2Instance).RunningInstance | Where-Object {$_.instanceId -eq $instanceId} |select Tag
$tagName = $tags.Tag | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value
 
return $tagName
 
}
$name = ((get-ec2instance)[0].RunningInstance[0].Tag | select-object Value).Value
