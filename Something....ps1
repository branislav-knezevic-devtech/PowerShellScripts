$regions = Get-EC2Region
foreach ($r in $regions)
{
    Set-DefaultAWSRegion -Region $r.region
    Get-EC2Instance | where { ($_.instanceid -eq "i-0e31634e4b2eea03f") -or ($_.instanceid -eq "i-0accca26d3a933311")}


(Get-EC2Instance).Instances | select InstanceID, ImageID, InstanceType, KeyName, Launchtime, state.name
((Get-EC2Instance -InstanceId i-040d61fb1a12b5f96).Instances).state.name

#instance state shouldn't be terminated
# count terminated licenses and add them just for statistcs. 

# Get all running instances in all regions following Don Jones tool making part guidef

$Regions = Get-EC2Region
ForEach ( $Region in $Regions ) 
{
    try 
    {
        $RegionName = $Region.RegionName
        Set-DefaultAWSRegion -Region $RegionName -ErrorAction Stop
        if ( (Get-EC2Instance -Region $RegionName) -eq $null )
        {
            $noInstances = "There are no instances in $RegionName"
        }
        else
        {
            $Instances = (Get-EC2Instance -Region $RegionName).Instances
            $InstancesCount = $Instances.count 
            foreach ($i in $Instances)
            {
                $InstanceState = ((Get-EC2Instance -InstanceId $i.intanceid).Instances).state.name
                $instanceDetail = $i.Instances
                $instanceProperties = @{ InstanceID = $instanceDetail.instanceID
                                         InstanceType = $instanceDetail.instanceType
                                         KeyName = $instanceDetail.keyname
                                         LaunchTime = $instanceDetail.launchTime
                                         InstanceState = $InstanceState }
            }
        }

    }
    catch
    {
        Write-Warning "AWS is having problems to connect to region $RegionName"
    }
    finally
    {
        if ($InstancesCount -gt 0)
        {
            if ($InstancesCount -eq 1)
            {
                Write-Output "$InstancesCount instance found in $RegionName"
            }
            else
            {
                Write-Output "$InstancesCount instances found in $RegionName"
            }
            Write-Output $InstanceProperties
        }
        Else
        {
            Write-Output $noInstances
        }
    }
}

<#
can be added here
BEGIN {}
PROCESS {}
END {}
#>