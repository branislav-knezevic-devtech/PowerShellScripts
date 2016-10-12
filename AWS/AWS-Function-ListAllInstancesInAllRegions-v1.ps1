# Get all running instances in all regions following Don Jones toomaking part guide

$Regions = Get-EC2Region
ForEach ( $Region in $Regions ) 
{
    try 
    {
        $RegionName = $Region.RegionName
        Set-DefaultAWSRegion -Region $RegionName -ErrorAction Stop
        $Instances = (Get-EC2Instance).Instances # | select ImageId,InstanceType,KeyName,LaunchTime 
        $InstanceProperties = @{ RegionName = $RegionName
                                 InstanceID = $Instances.imageid
                                 InstanceType = $Instances.InstanceType
                                 KeyName = $Instances.KeyName
                                 LaunchTime = $Instances.LaunchTime } 
        $obj = New-Object -TypeName PSObject -Property $InstanceProperties
        if ($instances.count -gt 0)
        {    
            Write-Output $obj
        }
    }
    catch
    {
        $InstanceProperties = @{ RegionName = $RegionName
                                 InstanceID = $null
                                 InstanceType = $null
                                 KeyName = $null
                                 LaunchTime = $null } 
            $obj = New-Object -TypeName PSObject -Property $InstanceProperties
            if ($instances.count -gt 0)
            {    
                Write-Output $obj
            }
    }
}