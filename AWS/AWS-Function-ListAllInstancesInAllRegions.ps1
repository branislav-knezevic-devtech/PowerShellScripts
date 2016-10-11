# funkctioon Get-AllInstances lists all running instances grouped by region

function Get-AllInstances {

    $Regions = Get-EC2Region
    $AllInstances = ForEach ( $Region in $Regions ) {
        $RegionName = $Region.RegionName
        Set-DefaultAWSRegion -Region $RegionName
        Write-Output `n "Instances in $RegionName :"
        (Get-EC2Instance).Instances | select ImageId,InstanceType,KeyName,LaunchTime 
    }
    Return $AllInstances
}