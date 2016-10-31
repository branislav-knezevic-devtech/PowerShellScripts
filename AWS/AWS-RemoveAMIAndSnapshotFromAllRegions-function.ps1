# Goes through all regions except eu-central-1, locates desired image(AMI) and snapshot and removes them

param 
(
    [string]$ImageID
)

# $ImageID = "ami-81f00eee"get
$OwnerID = "989786818629"
$ImageName = (Get-EC2Image -ImageId $ImageID).name
$CurrentRegion = (Get-DefaultAWSRegion).Region
$Regions = Get-EC2Region | where {$_.Region -notlike $CurrentRegion}
ForEach ($Region in $Regions) 
{
    try
    {
        $RegionName = $Region.RegionName
        Set-DefaultAWSRegion -Region $RegionName
        $ImageForRemoval = (Get-EC2Image | where {$_.name -like $ImageName}).imageid
        Unregister-EC2Image -ImageId $ImageForRemoval -ErrorAction stop
               
        if ((Get-EC2Snapshot).Description -like "*$ImageID*") 
	    {
            $SnapshotForRemoval = (Get-EC2Snapshot | where { $_.Description -like "*$ImageID*" }).SnapshotId
            Remove-EC2Snapshot -SnapshotId $SnapshotForRemoval -ErrorAction stop
        }
    }
    catch
    {
        Write-Warning "Image $ImageForRemoval which is a copy of $ImageName was not found in $RegionName"
        Write-Warning "Snapshot $SnapshotForRemoval which belogns to $ImageForRemoval was not found in $RegionName"
    }
    Finally
    {
        Write-Output "Image $ImageForRemoval has been unregistered in $RegionName"
        if ($SnapshotForRemoval -notlike $null)
        {
            Write-Output "Snapshot $SnapshotForRemoval which belonged to image $ImageForRemoval has been deleted"
        }
    }
}