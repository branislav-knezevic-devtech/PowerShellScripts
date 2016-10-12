
# Goes through all regions except eu-central-1, locates desired image(AMI) and snapshot and removes them

$ImageID = "ami-81f00eee" # this can be set as parametar or to prompt the user
$OwnerID = "989786818629"
$ImageName = "BK-AMI-Image"

$Regions = Get-EC2Region | where { $_.Region -notlike "eu-central-1" }
ForEach ( $Region in $Regions ) 
{
    $RegionName = $Region.RegionName
    Set-DefaultAWSRegion -Region $RegionName
    if ( (Get-EC2Image).Name -eq $ImageName ) 
	{
        $ImageForRemoval = (Get-EC2Image | where { $_.name -like $ImageName }).imageid
        Unregister-EC2Image -ImageId $ImageForRemoval
    }
	else { Write-Host "Image $ImageForRemoval which is a copy of $ImageName was not found in $RegionName" }
    if ( (Get-EC2Snapshot).Description -like "*$ImageID*" ) 
	{
        $SnapshotForRemoval = (Get-EC2Snapshot | where { $_.Description -like "*$ImageID*" }).SnapshotId
        Remove-EC2Snapshot -SnapshotId $SnapshotForRemoval
    }
}

