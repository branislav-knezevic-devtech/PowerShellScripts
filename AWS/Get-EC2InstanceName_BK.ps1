function Get-EC2InstanceName_BK
{
	<#
		.SYNOPSIS
			Returns Name Tag for selected instance
			         
		.DESCRIPTION
			When ID of instance is specified, it returns Name tag which has been set on AWS   

		.EXAMPLE
		    Get-EC2InstanceName_BK [instanceID]

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