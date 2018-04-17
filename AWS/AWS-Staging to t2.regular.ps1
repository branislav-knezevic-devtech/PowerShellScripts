<#
    Go through all instances on Staging and set instance type for each instance
    as it was before they were reduced to nano. 
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

# All instances must be listed in appropriate arrays by instance type before this is initiated
$micro = "MigrationStatusChange-Stagnig", "WCF-Staging"
$small = "Webserver-Staging", "Mongo-Staging"
$medium = "MessageHandler-Staging"
$Instances = (Get-EC2InstanceStatus).InstanceId 
foreach ($id in $Instances)
{
    if ( $micro -contains (Get-EC2InstanceName $id))
    {
        Stop-EC2Instance -InstanceId $id | Out-Null
        do
        {
            start-sleep -Seconds 5
        }
        until ((Get-EC2Instance -InstanceId $id).Instances.state.name.value -eq "stopped")
        Edit-EC2InstanceAttribute -InstanceId $id -InstanceType t2.micro | Out-Null
        Start-EC2Instance -InstanceId $id | Out-Null
        do
        {
            start-sleep -Seconds 5
        }
        until ((Get-EC2Instance -InstanceId $id).Instances.state.name.value -eq "running")
        $name = (Get-EC2InstanceName $id)
        Write-Host Instance $name ($id) is now running as t2.micro -ForegroundColor Cyan
    }
    elseif ( $small -contains (Get-EC2InstanceName $id))
    {
        Stop-EC2Instance -InstanceId $id | Out-Null
        do
        {
            start-sleep -Seconds 5
        }
        until ((Get-EC2Instance -InstanceId $id).Instances.state.name.value -eq "stopped")
        Edit-EC2InstanceAttribute -InstanceId $id -InstanceType t2.small | Out-Null
        Start-EC2Instance -InstanceId $id | Out-Null
        do
        {
            start-sleep -Seconds 5
        }
        until ((Get-EC2Instance -InstanceId $id).Instances.state.name.value -eq "running")
        $name = (Get-EC2InstanceName $id)
        Write-Host Instance $name ($id) is now running as t2.small -ForegroundColor Cyan
    }
     elseif ( $medium -contains (Get-EC2InstanceName $id))
    {
        Stop-EC2Instance -InstanceId $id | Out-Null
        do
        {
            start-sleep -Seconds 5
        }
        until ((Get-EC2Instance -InstanceId $id).Instances.state.name.value -eq "stopped")
        Edit-EC2InstanceAttribute -InstanceId $id -InstanceType t2.medium | Out-Null
        Start-EC2Instance -InstanceId $id | Out-Null
        do
        {
            start-sleep -Seconds 5
        }
        until ((Get-EC2Instance -InstanceId $id).Instances.state.name.value -eq "running")
        $name = (Get-EC2InstanceName $id)
        Write-Host Instance $name ($id) is now running as t2.medium -ForegroundColor Cyan
    }
    else
    {
        Write-Host Instance $id is just a worker. -ForegroundColor Cyan
    }
}


