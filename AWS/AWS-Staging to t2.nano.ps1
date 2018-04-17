<#
    Reduces all instances in staging to t2.nano
#>

Initialize-AWSDefaults
Set-DefaultAWSRegion us-east-1

function Get-EC2InstanceName
{
	[CmdletBinding()]
	param 
	(
	    [Parameter(Mandatory=$false,
	               Position=1,
	               ValueFromPipeline=$false,
	               ValueFromPipelineByPropertyName=$False)]
	    $instanceId 
	)
	 
	$tags = (Get-EC2Instance).RunningInstance | Where-Object {$_.instanceId -eq $instanceId} | select Tag
	$tagName = $tags.Tag | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value
	 
	return $tagName
}

$instances = (Get-EC2InstanceStatus).InstanceId
ForEach ($id in $instances)
{
    Stop-EC2Instance -InstanceId $id | Out-Null
    do
    {
        start-sleep -Seconds 5
    }
    until ((Get-EC2Instance -InstanceId $id).Instances.state.name.value -eq "stopped")
    Edit-EC2InstanceAttribute -InstanceId $id -InstanceType t2.nano | Out-Null
    Start-EC2Instance -InstanceId $id | Out-Null
    do
    {
        start-sleep -Seconds 5
    }
    until ((Get-EC2Instance -InstanceId $id).Instances.state.name.value -eq "running")
    $name = Get-EC2InstanceName $id
    Write-host "Instance $name ($id) is now running as t2.nano" -ForegroundColor Cyan
}


