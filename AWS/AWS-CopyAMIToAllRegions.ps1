$Regions = Get-EC2Region
$ImageID =  ( Get-EC2Image | where { $_.OwnerId -like "989786818629" } ).ImageId
ForEach ( $Region in $Regions ) {
    $RegionName = $Region.RegionName
    Set-DefaultAWSRegion -Region $RegionName
    if ( (Get-EC2Image).ImageId -notcontains $imageID ) {
        Copy-EC2Image -SourceRegion eu-central-1 -SourceImageId $ImageID -Region $RegionName
    }
}