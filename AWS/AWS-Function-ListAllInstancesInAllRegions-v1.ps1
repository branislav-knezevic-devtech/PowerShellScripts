# Get all running instances in all regions following Don Jones toomaking part guide

$Regions = Get-EC2Region
ForEach ( $Region in $Regions ) 
{
    try 
    {
        $RegionName = $Region.RegionName
        Set-DefaultAWSRegion -Region $RegionName -ErrorAction Stop
        $Instances = (Get-EC2Instance).Instances # | select ImageId,InstanceType,KeyName,LaunchTime
        if ( $instances.count -gt 0 )
        { 
            $InstanceProperties = @{ RegionName = $RegionName
                                     RegionStatus = 'Available'
                                     InstanceID = $Instances.imageid
                                     InstanceType = $Instances.InstanceType
                                     KeyName = $Instances.KeyName
                                     LaunchTime = $Instances.LaunchTime } 
        }
    }
    catch
    {
         $InstanceProperties = @{ RegionName = $RegionName
                                     RegionStatus = 'Unvailable'
                                     InstanceID = $null
                                     InstanceType = $null
                                     KeyName = $null
                                     LaunchTime = $null } 
    }
    finally
    {
       if ( $instances.count -gt 0 )
       {
            $obj = New-Object -TypeName PSObject -Property $InstanceProperties
            Write-Output $obj
       }
       Else
       {
            Write-Host "There are no instances in region $RegionName"
       }
    }
}