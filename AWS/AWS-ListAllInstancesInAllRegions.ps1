$Regions = Get-EC2Region
ForEach ( $Region in $Regions ) {
    $RegionName = $Region.RegionName
    Set-DefaultAWSRegion -Region $RegionName
    Write-Output `n "Instances in $RegionName :"
    (Get-EC2Instance).Instances | select ImageId,InstanceType,KeyName,LaunchTime 
}