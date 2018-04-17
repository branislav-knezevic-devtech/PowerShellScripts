<#
    This is a deployment script which can be implemented in CI-CD process
    First Autoscaling configuration must be created manually and name must be specified in the code below in variable $LaunchConfiguration
    This script does not update any Autoscaling rules
#>

Initialize-AWSDefaults
Set-DefaultAWSRegion eu-central-1

function Get-EC2InstanceName
{
	<#
		.SYNOPSIS
			Returns Name Tag for selected instance
			         
		.DESCRIPTION
			When ID of instance is specified, it returns Name tag which has been set on AWS   

		.EXAMPLE
		    Get-EC2InstanceName [instanceID]

		    Returns given name e.g Webserver
	#>
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

# Get ID of an instance which is named Webserver-QA
$WebserverName = "Webserver-QA"
$Instances = (Get-EC2InstanceStatus).InstanceId 
foreach ($i in $Instances)
{
    if ( (Get-EC2InstanceName $i) -eq "$WebserverName" )
    {
        Write-Output "Instance ID of the Webserver is: $i"
        $WebserverID = $i
    }
    else {}
}

# Create image of latest version of Webserver and remove the older one
# during that process assign temp autoscaling group to default launch configuration so the AMI could be replaced

$date = (Get-Date).DateTime -replace ",", "" -replace " ", "-" -replace ":", "-"

$newImage = New-EC2Image -InstanceId $WebserverID -Name "Webserver-QA-AMI-$date" 

Update-ASAutoScalingGroup -AutoScalingGroupName "Webserver-autoscaling" -LaunchConfigurationName "temp-launch-configuration"

$LaunchConfiguration = "Webserver-QA-Recovery"
if ((Get-ASLaunchConfiguration).LaunchConfigurationName -contains "$LaunchConfiguration")
{
    Remove-ASLaunchConfiguration -LaunchConfigurationName $LaunchConfiguration -Force -Confirm:$false 
}
else {}

# remove old images
$oldImage = (Get-EC2Image -Owner self | where {$_.imageid -notlike "$newImage"}).ImageId
foreach ($image in $oldImage)
{
    Unregister-EC2Image -ImageId $image -Force -Confirm:$false
}

Start-Sleep -Seconds 300

#remove old snapshots
$oldSnaps = (Get-EC2Snapshot -OwnerId 989786818629 | where { ($_.description -notlike "*$newImage*") -and ($_.description -notlike "*i-586b3ae4*") }).snapshotId
foreach ($snap in $oldSnaps)
{
    Remove-EC2Snapshot -SnapshotId $snap -Force -Confirm:$false
}

New-ASLaunchConfiguration -LaunchConfigurationName $LaunchConfiguration -InstanceType "t2.small" -ImageId $newImage -SecurityGroup sg-8964d4e1,sg-abd245c3,sg-e3615c8b -IamInstanceProfile "Webserver" -KeyName "devtech"

Update-ASAutoScalingGroup -AutoScalingGroupName "Webserver-Autoscaling" -LaunchConfigurationName $LaunchConfiguration


