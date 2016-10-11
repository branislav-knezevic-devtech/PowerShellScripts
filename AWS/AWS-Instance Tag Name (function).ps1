#Creates new function Get-Ec2InstanceName which returns instances tag when InstanceId is provided
function Get-EC2InstanceName ($instanceId) 
{
 
$tags = (Get-EC2Instance).RunningInstance | Where-Object {$_.instanceId -eq $instanceId} | select Tag
$tagName = $tags.Tag | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value
 
return $tagName
 
}