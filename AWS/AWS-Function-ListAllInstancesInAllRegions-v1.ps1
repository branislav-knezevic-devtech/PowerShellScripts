# Get all running instances in all regions following Don Jones toomaking part guide

$Regions = Get-EC2Region
ForEach ( $Region in $Regions ) 
{
    try 
    {
        $RegionName = $Region.RegionName
        Set-DefaultAWSRegion -Region $RegionName -ErrorAction Stop
        $Instances = (Get-EC2Instance).Instances
        $InstancesCount = $Instances.count 
        if ($InstancesCount -gt 0)
        { 
            $InstanceProperties = $Instances | select InstanceID,InstanceType,KeyName,LaunchTime | fl
            
        }
    }
    catch
    {
        Write-Warning "AWS is having problems to connect to region $RegionName"
    }
    finally
    {
        if ($instances.count -gt 0)
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
            Write-Output "There are no instances in region $RegionName"
        }
    }
}

# for output play with simple select, maybe as | fl
# with select option script needs to be changed as $obj has to be removed